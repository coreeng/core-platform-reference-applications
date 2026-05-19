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
}
