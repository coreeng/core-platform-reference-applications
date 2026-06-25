resource "google_project_service_identity" "managed_kafka" {
  provider = google-beta

  project = var.infrastructure_project_id
  service = "managedkafka.googleapis.com"

  depends_on = [module.project-services]
}

resource "google_project_iam_member" "managed_kafka_service_agent" {
  for_each = local.service_agent_project_grants

  project = each.value
  role    = "roles/managedkafka.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.managed_kafka.email}"
}

resource "google_managed_kafka_cluster" "cluster" {
  for_each = local.clusters

  project         = var.infrastructure_project_id
  cluster_id      = each.value.cluster_id
  location        = var.region
  labels          = each.value.labels
  deletion_policy = each.value.deletion_policy

  capacity_config {
    vcpu_count   = each.value.vcpu_count
    memory_bytes = each.value.memory_bytes
  }

  gcp_config {
    access_config {
      dynamic "network_configs" {
        for_each = each.value.connected_subnets
        content {
          subnet = network_configs.value.subnet
        }
      }
    }
  }

  rebalance_config {
    mode = each.value.rebalance_mode
  }

  depends_on = [
    module.project-services,
    google_project_iam_member.managed_kafka_service_agent,
  ]
}

resource "google_project_iam_member" "managed_kafka_client" {
  for_each = local.client_principals

  project = var.infrastructure_project_id
  role    = "roles/managedkafka.client"
  member  = each.value
}

resource "google_managed_kafka_topic" "topic" {
  for_each = local.topics

  project            = var.infrastructure_project_id
  location           = var.region
  cluster            = each.value.cluster_id
  topic_id           = each.value.name
  partition_count    = each.value.partition_count
  replication_factor = each.value.replication_factor
  configs            = each.value.configs
  deletion_policy    = each.value.deletion_policy

  depends_on = [google_managed_kafka_cluster.cluster]
}

resource "google_managed_kafka_acl" "acl" {
  for_each = local.acls

  project         = var.infrastructure_project_id
  location        = var.region
  cluster         = each.value.cluster_id
  acl_id          = each.value.id
  deletion_policy = each.value.deletion_policy

  dynamic "acl_entries" {
    for_each = each.value.entries
    content {
      principal       = acl_entries.value.principal
      operation       = acl_entries.value.operation
      permission_type = acl_entries.value.permission_type
      host            = acl_entries.value.host
    }
  }

  depends_on = [
    google_managed_kafka_cluster.cluster,
    google_managed_kafka_topic.topic,
  ]
}
