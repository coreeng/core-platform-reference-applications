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
    ipv4_enabled                  = true
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

  #enable_default_user = false

  connector_enforcement = each.value.connector_enforcement

  user_name     = "postgres"
  user_password = random_password.cloudsql_initial_password.result
}