data "google_project" "platform_project" {
  project_id = var.platform_project_id
  depends_on = [module.project-services]
}

resource "random_password" "cloudsql_initial_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "google_compute_network" "psa" {
  name                    = "cloudsql-${var.environment}-psa"
  project                 = var.infrastructure_project_id
  auto_create_subnetworks = false
  description             = "Cloud SQL PSA network"
  depends_on              = [module.project-services]
}

module "cloudsql-psa" {
  source  = "terraform-google-modules/sql-db/google//modules/private_service_access"
  version = "26.2.2"

  depends_on  = [module.project-services, google_compute_network.psa]
  project_id  = var.infrastructure_project_id
  vpc_network = google_compute_network.psa.name
  address     = "10.220.0.0"
}

module "cloudsql-postgresql" {
  for_each   = local.postgresql_clusters_map
  source     = "terraform-google-modules/sql-db/google//modules/postgresql"
  version    = "26.2.2"
  depends_on = [module.project-services, module.cloudsql-psa]
  project_id = var.infrastructure_project_id
  region     = var.region
  name       = "${each.key}-${var.environment}-cluster"

  availability_type = each.value.availability_type

  database_version   = each.value.database_version
  edition            = each.value.edition
  activation_policy  = each.value.activation_policy
  data_cache_enabled = each.value.data_cache_enabled

  tier                  = each.value.tier
  disk_type             = each.value.disk_type
  disk_autoresize       = each.value.disk_autoresize
  disk_autoresize_limit = each.value.disk_autoresize_limit
  disk_size             = each.value.disk_size

  maintenance_window_day          = each.value.maintenance_window_day
  maintenance_window_hour         = each.value.maintenance_window_hour
  maintenance_window_update_track = each.value.maintenance_window_update_track

  deletion_protection         = each.value.deletion_protection
  deletion_protection_enabled = each.value.deletion_protection
  database_deletion_policy    = each.value.database_deletion_policy
  retain_backups_on_delete    = each.value.retain_backups_on_delete

  database_flags = each.value.database_flags
  iam_users      = each.value.iam_users

  insights_config = {
    query_plans_per_minute  = each.value.insights_config.query_plans_per_minute
    query_string_length     = each.value.insights_config.query_string_length
    record_application_tags = each.value.insights_config.record_application_tags
    record_client_address   = each.value.insights_config.record_client_address
  }

  ip_configuration = {
    ssl_mode                      = "ENCRYPTED_ONLY"
    authorized_networks           = var.cloudsql.allowed_ip_ranges
    ipv4_enabled                  = each.value.public_ip_enabled
    private_network               = google_compute_network.psa.id
    psc_enabled                   = true
    psc_allowed_consumer_projects = [data.google_project.platform_project.number]
  }

  backup_configuration = {
    enabled                        = each.value.backup_configuration.enabled
    start_time                     = each.value.backup_configuration.start_time
    location                       = each.value.backup_configuration.location
    point_in_time_recovery_enabled = each.value.backup_configuration.point_in_time_recovery_enabled
    transaction_log_retention_days = each.value.backup_configuration.transaction_log_retention_days
    retained_backups               = each.value.backup_configuration.retained_backups
    retention_unit                 = each.value.backup_configuration.retention_unit
  }

  enable_default_db    = false
  additional_databases = each.value.databases

  # Default postgres user is required for the provisioner to grant privileges to IAM users
  # Do not disable unless switching to a different privilege grant mechanism
  user_name     = "postgres"
  user_password = random_password.cloudsql_initial_password.result

  # Connector enforcement requires all connections to use Cloud SQL Auth Proxy or connector library
  connector_enforcement = each.value.connector_enforcement

  # Password validation policy
  password_validation_policy_config = each.value.password_validation_policy_config
}

# Grant Cloud SQL Client role to all IAM users
# This allows them to call the Cloud SQL Admin API for connection info
resource "google_project_iam_member" "cloudsql_client" {
  for_each = local.iam_users

  project = var.infrastructure_project_id
  role    = "roles/cloudsql.client"
  member  = each.value
}

# Grant Cloud SQL Instance User role to all IAM users
# This allows them to authenticate to Cloud SQL instances using IAM
resource "google_project_iam_member" "cloudsql_instance_user" {
  for_each = local.iam_users

  project = var.infrastructure_project_id
  role    = "roles/cloudsql.instanceUser"
  member  = each.value
}

# Grant Service Usage Consumer role to IAM service accounts only
# This allows the service accounts from the platform project to access Cloud SQL in the infrastructure project
resource "google_project_iam_member" "service_usage_consumer" {
  for_each = local.service_account_iam_users

  project = var.infrastructure_project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = each.value
}

# Grant Cloud SQL Viewer role to all IAM users
# This allows them to list databases and users in Cloud SQL instances
resource "google_project_iam_member" "cloudsql_viewer" {
  for_each = local.iam_users

  project = var.infrastructure_project_id
  role    = "roles/cloudsql.viewer"
  member  = each.value
}

# Grant comprehensive privileges to IAM users specified for each database
resource "null_resource" "grant_iam_user_privileges" {
  for_each = {
    for combo in flatten([
      for cluster_name, cluster in local.postgresql_clusters_map : [
        for db in cluster.databases : [
          for iam_user in db.iam_users : {
            key          = "${cluster_name}/${db.name}/${iam_user.id}"
            cluster_name = "${cluster_name}-${var.environment}-cluster"
            database     = db.name
            # CloudSQL truncates IAM usernames to end at .iam (63 char PostgreSQL limit)
            iam_user = replace(iam_user.email, ".iam.gserviceaccount.com", ".iam")
            roles    = try(iam_user.roles, [])
          }
        ]
      ]
    ]) : combo.key => combo
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -e

      # Ensure proxy process is cleaned up on exit or error
      # EXIT trap works with set -e to catch both normal exit and errors
      cleanup_proxy() {
        if [ ! -z "$PROXY_PID" ]; then
          echo "Cleaning up Cloud SQL Proxy (PID: $PROXY_PID)..."
          kill $PROXY_PID 2>/dev/null || true
          wait $PROXY_PID 2>/dev/null || true
        fi
      }
      trap cleanup_proxy EXIT

      echo "Granting privileges on database '${each.value.database}' to '${each.value.iam_user}'..."

      # Get connection name for Cloud SQL Proxy
      CONNECTION_NAME=$(gcloud sql instances describe ${each.value.cluster_name} \
        --project=${var.infrastructure_project_id} \
        --format='value(connectionName)')

      # Start Cloud SQL Proxy in background on random port with retry logic
      MAX_PORT_RETRIES=10
      PROXY_STARTED=false

      for port_attempt in $(seq 1 $MAX_PORT_RETRIES); do
        PROXY_PORT=$((30000 + RANDOM % 10000))
        echo "Attempt $port_attempt: Starting Cloud SQL Proxy on port $PROXY_PORT..."

        # Start proxy and capture output
        cloud-sql-proxy "$CONNECTION_NAME" --port=$PROXY_PORT &
        PROXY_PID=$!

        # Give proxy a moment to fail if port is in use
        sleep 1

        # Check if proxy is still running (it exits immediately if port is in use)
        if kill -0 $PROXY_PID 2>/dev/null; then
          PROXY_STARTED=true
          echo "Cloud SQL Proxy started successfully on port $PROXY_PORT"
          break
        else
          echo "Port $PROXY_PORT was in use, trying another port..."
          PROXY_PID=""
        fi
      done

      if [ "$PROXY_STARTED" = false ]; then
        echo "ERROR: Failed to start Cloud SQL Proxy after $MAX_PORT_RETRIES attempts"
        exit 1
      fi

      # Wait for proxy to be ready with retry logic (max 30 seconds)
      echo "Waiting for Cloud SQL Proxy to be ready..."
      for i in $(seq 1 30); do
        if pg_isready -h 127.0.0.1 -p $PROXY_PORT -U postgres -q 2>/dev/null; then
          echo "Cloud SQL Proxy is ready after $i seconds"
          break
        fi
        if [ $i -eq 30 ]; then
          echo "ERROR: Cloud SQL Proxy failed to become ready after 30 seconds"
          exit 1
        fi
        sleep 1
      done

      # Execute SQL via psql (password provided via PGPASSWORD environment variable)
      # Note: Some grants may fail if postgres user doesn't own certain objects (e.g., flyway_schema_history)
      # This is expected and acceptable - psql will continue without ON_ERROR_STOP
      echo "Executing privilege grants..."
      psql -h 127.0.0.1 -p $PROXY_PORT -U postgres -d ${each.value.database} \
        -c "GRANT ALL PRIVILEGES ON DATABASE \"${each.value.database}\" TO \"${each.value.iam_user}\";" \
        -c "GRANT ALL PRIVILEGES ON SCHEMA public TO \"${each.value.iam_user}\";" \
        -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \"${each.value.iam_user}\";" \
        -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO \"${each.value.iam_user}\";" \
        -c "GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO \"${each.value.iam_user}\";" \
        -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO \"${each.value.iam_user}\";" \
        -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO \"${each.value.iam_user}\";" \
        -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON FUNCTIONS TO \"${each.value.iam_user}\";"

      # Grant PostgreSQL roles if specified
      ROLES="${join(",", each.value.roles)}"
      if [ ! -z "$ROLES" ]; then
        echo "Granting PostgreSQL roles to '${each.value.iam_user}': $ROLES"
        IFS=',' read -ra ROLE_ARRAY <<< "$ROLES"
        for role in "$${ROLE_ARRAY[@]}"; do
          if [ ! -z "$role" ]; then
            echo "  Granting role: $role"
            psql -h 127.0.0.1 -p $PROXY_PORT -U postgres -d ${each.value.database} \
              -c "GRANT \"$role\" TO \"${each.value.iam_user}\";" || echo "  Warning: Failed to grant role $role (may not exist or already granted)"
          fi
        done
      fi

      echo "Privileges granted successfully (errors for non-postgres owned objects are expected)"
    EOT

    environment = {
      PGPASSWORD = nonsensitive(random_password.cloudsql_initial_password.result)
    }
  }

  depends_on = [
    module.cloudsql-postgresql,
    google_project_iam_member.cloudsql_client
  ]

  triggers = {
    cluster  = each.value.cluster_name
    database = each.value.database
    iam_user = each.value.iam_user
    roles    = join(",", each.value.roles)
    # Increment this version to force re-run
    grant_version = "v1"
  }
}

# Apply password verification to the postgres user to satisfy Google Cloud security recommendations
resource "null_resource" "apply_user_password_policy" {
  for_each = local.postgresql_clusters_map

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -e

      echo "Applying password policy to postgres user on instance '${each.key}-${var.environment}-cluster'..."

      gcloud sql users set-password-policy postgres \
        --instance=${each.key}-${var.environment}-cluster \
        --project=${var.infrastructure_project_id} \
        --host=% \
        --password-policy-enable-password-verification

      echo "Password verification enabled for postgres user"
    EOT
  }

  depends_on = [
    module.cloudsql-postgresql
  ]

  triggers = {
    cluster = "${each.key}-${var.environment}-cluster"
    # Increment this version to force re-run
    policy_version = "v1"
  }
}
