locals {
  # map postgres clusters by name for easy for_each
  postgres_clusters_map = { for r in var.cloudsql.clusters.postgres : r.name => r }
}