variable "infrastructure_project_id" {
  type = string
}

variable "platform_project_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "cloudsql" {
  description = "Cloud SQL configuration"
  type = object({
    enabled              = bool
    psa_enabled          = optional(bool, false)
    manage_psa_resources = optional(bool)
    psc_enabled          = optional(bool, false)
    allowed_ip_ranges    = optional(list(map(string)), [])
    monitoring = optional(object({
      notification_emails = optional(list(string), [])
      thresholds = optional(object({
        cpu_utilization      = optional(number, 0.9)
        disk_utilization     = optional(number, 0.8)
        memory_utilization   = optional(number, 0.9)
        read_ops_per_second  = optional(number, 1000)
        write_ops_per_second = optional(number, 1000)
      }), {})
    }), {})
    ids = optional(object({
      enabled               = optional(bool, false)
      location              = optional(string)
      severity              = optional(string, "INFORMATIONAL")
      packet_mirroring_tags = optional(list(string), ["cloudsql-psa"])
      notifications_enabled = optional(bool, true)
    }), {})
    clusters = optional(object({
      postgresql = optional(list(object({
        name               = string
        tier               = string
        database_version   = string
        edition            = optional(string, "ENTERPRISE")
        psa_enabled        = optional(bool)
        psc_enabled        = optional(bool)
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

  validation {
    condition     = contains(["INFORMATIONAL", "LOW", "MEDIUM"], try(var.cloudsql.ids.severity, "INFORMATIONAL"))
    error_message = "cloudsql.ids.severity must be INFORMATIONAL, LOW, or MEDIUM."
  }

  validation {
    condition     = !try(var.cloudsql.ids.enabled, false) || (try(var.cloudsql.psa_enabled, false) && coalesce(try(var.cloudsql.manage_psa_resources, null), true))
    error_message = "cloudsql.ids.enabled requires cloudsql.psa_enabled and managed PSA resources because Cloud IDS mirrors the PSA VPC."
  }

  validation {
    condition = alltrue([
      for cluster in try(var.cloudsql.clusters.postgresql, []) :
      try(cluster.public_ip_enabled, true) || coalesce(try(cluster.psa_enabled, null), try(var.cloudsql.psa_enabled, false)) || coalesce(try(cluster.psc_enabled, null), try(var.cloudsql.psc_enabled, false))
    ])
    error_message = "Cloud SQL clusters with public_ip_enabled=false require psa_enabled or psc_enabled at the cluster or cloudsql level."
  }
}
