locals {
  # map postgresql clusters by name for easy for_each with automatic IAM authentication flag
  postgresql_clusters_map = {
    for r in var.cloudsql.clusters.postgresql : r.name => merge(r, {
      # Automatically add cloudsql.iam_authentication flag if any database has iam_users configured
      database_flags = length(flatten([for db in r.databases : db.iam_users])) > 0 ? concat(
        # Add the IAM authentication flag if not already present
        contains([for flag in r.database_flags : flag.name], "cloudsql.iam_authentication") ? [] : [{
          name  = "cloudsql.iam_authentication"
          value = "on"
        }],
        # Include all user-defined flags
        r.database_flags
      ) : r.database_flags
      # Collect all unique IAM users from all databases for this cluster
      iam_users = distinct(flatten([for db in r.databases : db.iam_users]))
    })
  }
}