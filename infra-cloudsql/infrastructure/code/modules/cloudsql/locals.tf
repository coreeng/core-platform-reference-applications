locals {
  # map postgresql clusters by name for easy for_each
  postgresql_clusters_map = { for r in var.cloudsql.clusters.postgresql : r.name => r }
}