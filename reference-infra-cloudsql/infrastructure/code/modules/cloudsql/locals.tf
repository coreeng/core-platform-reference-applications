locals {
  # Map postgresql clusters by name for easy for_each with automatic IAM authentication and audit flags
  postgresql_clusters_map = {
    for r in var.cloudsql.clusters.postgresql : r.name => merge(r, {
      # Automatically add database flags based on configuration
      database_flags = concat(
        # Add the IAM authentication flag if any database has iam_users configured and flag not already present
        length(flatten([for db in r.databases : db.iam_users])) > 0 && !contains([for flag in r.database_flags : flag.name], "cloudsql.iam_authentication") ? [{
          name  = "cloudsql.iam_authentication"
          value = "on"
        }] : [],
        # Add audit flags if audit is enabled and flags not already present
        r.audit_config.enabled && !contains([for flag in r.database_flags : flag.name], "cloudsql.enable_pgaudit") ? [{
          name  = "cloudsql.enable_pgaudit"
          value = "on"
        }] : [],
        r.audit_config.enabled && !contains([for flag in r.database_flags : flag.name], "pgaudit.log") ? [{
          name  = "pgaudit.log"
          value = r.audit_config.log_statement_classes
        }] : [],
        # Include all user-defined flags
        r.database_flags
      )
      # Collect all unique IAM users from all databases for this cluster
      iam_users = distinct(flatten([for db in r.databases : db.iam_users]))
    })
  }

  # All IAM users with correct prefix (serviceAccount:, group:, or user:)
  iam_users = toset(distinct(flatten([
    for cluster in local.postgresql_clusters_map : [
      for iam_user in cluster.iam_users :
      try(iam_user.type, "") == "CLOUD_IAM_GROUP" ? "group:${iam_user.email}" : (
        can(regex(".*@.*\\.iam\\.gserviceaccount\\.com$", iam_user.email)) ? "serviceAccount:${iam_user.email}" : "user:${iam_user.email}"
      )
    ]
  ])))

  # Service Account IAM users only
  service_account_iam_users = toset([
    for member in local.iam_users : member
    if can(regex("^serviceAccount:", member))
  ])

  cloudsql_notification_channels = [
    for channel in google_monitoring_notification_channel.cloudsql_email : channel.name
  ]

  psa_enabled                     = try(var.cloudsql.psa_enabled, false)
  psc_enabled                     = try(var.cloudsql.psc_enabled, false)
  cloud_ids_enabled               = try(var.cloudsql.ids.enabled, false) && local.psa_enabled
  cloud_ids_location              = coalesce(try(var.cloudsql.ids.location, null), "${var.region}-b")
  cloud_ids_severity              = try(var.cloudsql.ids.severity, "INFORMATIONAL")
  cloud_ids_packet_mirroring_tags = try(var.cloudsql.ids.packet_mirroring_tags, ["cloudsql-psa"])
  cloud_ids_notifications_enabled = try(var.cloudsql.ids.notifications_enabled, true)

  cloudsql_alert_metrics = {
    cpu_utilization = {
      display_name       = "CPU utilization"
      metric_type        = "cloudsql.googleapis.com/database/cpu/utilization"
      threshold          = var.cloudsql.monitoring.thresholds.cpu_utilization
      alignment_period   = "300s"
      per_series_aligner = "ALIGN_MEAN"
    }
    disk_utilization = {
      display_name       = "disk utilization"
      metric_type        = "cloudsql.googleapis.com/database/disk/utilization"
      threshold          = var.cloudsql.monitoring.thresholds.disk_utilization
      alignment_period   = "300s"
      per_series_aligner = "ALIGN_MEAN"
    }
    memory_utilization = {
      display_name       = "memory utilization"
      metric_type        = "cloudsql.googleapis.com/database/memory/utilization"
      threshold          = var.cloudsql.monitoring.thresholds.memory_utilization
      alignment_period   = "300s"
      per_series_aligner = "ALIGN_MEAN"
    }
    read_ops = {
      display_name       = "disk read ops"
      metric_type        = "cloudsql.googleapis.com/database/disk/read_ops_count"
      threshold          = var.cloudsql.monitoring.thresholds.read_ops_per_second
      alignment_period   = "60s"
      per_series_aligner = "ALIGN_RATE"
    }
    write_ops = {
      display_name       = "disk write ops"
      metric_type        = "cloudsql.googleapis.com/database/disk/write_ops_count"
      threshold          = var.cloudsql.monitoring.thresholds.write_ops_per_second
      alignment_period   = "60s"
      per_series_aligner = "ALIGN_RATE"
    }
  }

  cloudsql_alert_policies = merge({}, [
    for cluster_name in keys(local.postgresql_clusters_map) : {
      for metric_key, metric in local.cloudsql_alert_metrics : "${cluster_name}-${metric_key}" => merge(metric, {
        instance_name = "${cluster_name}-${var.environment}-cluster"
      })
    }
  ]...)
}
