output "clusters" {
  description = "Managed Kafka cluster resource names by configured cluster name"
  value = {
    for name, cluster in google_managed_kafka_cluster.cluster : name => cluster.name
  }
}
