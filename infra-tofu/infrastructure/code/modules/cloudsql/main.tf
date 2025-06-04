data "google_project" "platform_project" {
  project_id = var.platform_project_id
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
}

module "cloudsql-psa" {
  source  = "terraform-google-modules/sql-db/google//modules/private_service_access"
  version = "25.2.2"

  depends_on  = [google_compute_network.psa]
  project_id  = var.infrastructure_project_id
  vpc_network = google_compute_network.psa.name
  address     = "10.220.0.0"
}

module "cloudsql-postgresql" {
  for_each   = local.postgres_clusters_map
  source     = "terraform-google-modules/sql-db/google//modules/postgresql"
  version    = "25.2.2"
  project_id = var.infrastructure_project_id
  region     = var.region
  name       = "${each.key}-${var.environment}-cluster"

  availability_type = "REGIONAL"

  database_version = "POSTGRES_16"

  tier                  = each.value.tier
  disk_autoresize       = true
  disk_autoresize_limit = 250
  disk_size             = 50

  maintenance_window_day          = 7
  maintenance_window_hour         = 12
  maintenance_window_update_track = "stable"

  deletion_protection      = false
  database_deletion_policy = "ABANDON"

  database_flags = [{ name = "autovacuum", value = "off" }]

  insights_config = {
    query_plans_per_minute = 5
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
    enabled                        = true
    start_time                     = "23:00"
    location                       = null
    point_in_time_recovery_enabled = true
    transaction_log_retention_days = 14
    retained_backups               = 15
    retention_unit                 = "COUNT"
  }

  enable_default_db    = false
  additional_databases = each.value.databases

  #enable_default_user = false

  connector_enforcement = false

  user_name     = "postgres"
  user_password = random_password.cloudsql_initial_password.result
}