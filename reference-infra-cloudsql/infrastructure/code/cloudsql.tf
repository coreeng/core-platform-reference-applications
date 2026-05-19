variable "cloudsql" {
  description = "Cloud SQL configuration"
  type = object({
    enabled           = bool
    allowed_ip_ranges = optional(list(map(string)), [])
    clusters = optional(object({
      postgresql = optional(list(object({
        name               = string
        tier               = string
        database_version   = string
        edition            = optional(string, "ENTERPRISE")
        activation_policy  = optional(string, "ALWAYS")
        data_cache_enabled = optional(bool, false)
        databases = list(object({
          name      = string
          charset   = optional(string, "")
          collation = optional(string, "")
          iam_users = optional(list(object({
            id    = string
            email = string
            type  = optional(string)
            roles = optional(list(string), [])
          })), [])
        }))
        disk_size             = optional(number, 10)
        disk_type             = optional(string, "PD_SSD")
        disk_autoresize       = optional(bool, true)
        disk_autoresize_limit = optional(number, 0)
        availability_type     = optional(string, "ZONAL")
        backup_configuration = optional(object({
          enabled                        = optional(bool, true)
          start_time                     = optional(string, "01:00")
          location                       = optional(string, null)
          point_in_time_recovery_enabled = optional(bool, true)
          transaction_log_retention_days = optional(string, "7")
          retained_backups               = optional(number, 21)
          retention_unit                 = optional(string, "COUNT")
        }), {})
        database_flags = optional(list(object({
          name  = string
          value = string
        })), [])
        insights_config = optional(object({
          query_plans_per_minute  = optional(number, 5)
          query_string_length     = optional(number, 1024)
          record_application_tags = optional(bool, false)
          record_client_address   = optional(bool, false)
        }), {})
        maintenance_window_day          = optional(number, 1)
        maintenance_window_hour         = optional(number, 23)
        maintenance_window_update_track = optional(string, "stable")
        deletion_protection             = optional(bool, true)
        database_deletion_policy        = optional(string, "ABANDON")
        retain_backups_on_delete        = optional(bool, false)
        connector_enforcement           = optional(bool, true)
        public_ip_enabled               = optional(bool, true)
        password_validation_policy_config = optional(object({
          min_length                  = optional(number, 8)
          complexity                  = optional(string, "COMPLEXITY_DEFAULT")
          reuse_interval              = optional(number, 0)
          disallow_username_substring = optional(bool, true)
          password_change_interval    = optional(string)
        }), {})
        audit_config = optional(object({
          enabled               = optional(bool, true)
          log_statement_classes = optional(string, "all")
        }), {})
      })))
    }))
  })
}

module "cloudsql" {
  source = "./modules/cloudsql"
  count  = var.cloudsql.enabled ? 1 : 0

  infrastructure_project_id = var.infrastructure_project_id
  platform_project_id       = var.platform_project_id
  environment               = var.environment
  region                    = var.region
  cloudsql                  = var.cloudsql
}

output "cloudsql_initial_password" {
  description = "The initial password for Cloud SQL"
  value       = var.cloudsql.enabled ? module.cloudsql[0].initial_password : null
  sensitive   = true
}
