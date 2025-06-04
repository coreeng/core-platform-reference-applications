data "google_project" "platform_project" {
  project_id = var.platform_project_id
}

resource "random_password" "alloydb_initial_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

module "alloy-db" {
  for_each         = var.alloydb.clusters != null ? var.alloydb.clusters : {}
  source           = "GoogleCloudPlatform/alloy-db/google"
  version          = "4.1.0"
  project_id       = var.infrastructure_project_id
  cluster_id       = "${each.key}-${var.environment}-cluster"
  cluster_location = var.region
  cluster_labels   = {}

  cluster_initial_user = {
    user     = "postgres",
    password = random_password.alloydb_initial_password.result
  }

  psc_enabled                   = true
  psc_allowed_consumer_projects = [data.google_project.platform_project.number]

  database_version = "POSTGRES_16"

  automated_backup_policy = {
    location      = var.region
    backup_window = "3600s",
    enabled       = true,
    weekly_schedule = {
      days_of_week = ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"]
      start_times  = ["23:00:00:00", ]
    }
    time_based_retention_count = "1209600s"
  }

  primary_instance = {
    instance_type      = "PRIMARY",
    machine_cpu_count  = each.value.cpus,
    instance_id        = "${each.key}-${var.environment}-cluster-primary",
    display_name       = "${each.key}-${var.environment}-cluster-primary",
    ssl_mode           = "ENCRYPTED_ONLY",
    require_connectors = false,
    enable_public_ip   = true
    cidr_range         = var.alloydb.allowed_ip_ranges
    database_flags = {
      "password.enforce_complexity"                         = "on"
      "password.min_uppercase_letters"                      = "1"
      "password.min_numerical_chars"                        = "1"
      "password.min_pass_length"                            = "10"
      "password.enforce_password_does_not_contain_username" = "on"
    }
  }

  read_pool_instance = [
    {
      instance_id        = "${each.key}-${var.environment}-cluster-reader",
      display_name       = "${each.key}-${var.environment}-cluster-reader",
      ssl_mode           = "ENCRYPTED_ONLY",
      require_connectors = false,
      enable_public_ip   = true
      cidr_range         = var.alloydb.allowed_ip_ranges
      database_flags = {
        "password.enforce_complexity"                         = "on",
        "password.min_uppercase_letters"                      = "1"
        "password.min_numerical_chars"                        = "1"
        "password.min_pass_length"                            = "10"
        "password.enforce_password_does_not_contain_username" = "on"
      }
    }
  ]
}