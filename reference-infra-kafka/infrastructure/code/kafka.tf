variable "kafka" {
  description = "Managed Kafka configuration"
  type = object({
    enabled = bool
    clusters = optional(list(object({
      name            = string
      vcpu_count      = number
      memory_bytes    = number
      deletion_policy = optional(string, "PREVENT")
      labels          = optional(map(string), {})
      rebalance_mode  = optional(string, "AUTO_REBALANCE_ON_SCALE_UP")
      connected_subnets = list(object({
        subnet                   = string
        project_id               = optional(string)
        grant_service_agent_role = optional(bool, true)
      }))
      client_principals = optional(list(string), [])
      topics = optional(list(object({
        name               = string
        partition_count    = optional(number)
        replication_factor = optional(number, 3)
        configs            = optional(map(string), {})
        deletion_policy    = optional(string, "PREVENT")
      })), [])
      acls = optional(list(object({
        id              = string
        deletion_policy = optional(string, "PREVENT")
        entries = list(object({
          principal       = string
          operation       = string
          permission_type = optional(string, "ALLOW")
          host            = optional(string, "*")
        }))
      })), [])
    })), [])
  })

  validation {
    condition = alltrue([
      for cluster in var.kafka.clusters : contains(["MODE_UNSPECIFIED", "NO_REBALANCE", "AUTO_REBALANCE_ON_SCALE_UP"], cluster.rebalance_mode)
    ])
    error_message = "kafka.clusters[*].rebalance_mode must be MODE_UNSPECIFIED, NO_REBALANCE, or AUTO_REBALANCE_ON_SCALE_UP."
  }

  validation {
    condition = alltrue(flatten([
      for cluster in var.kafka.clusters : [
        for policy in concat([cluster.deletion_policy], [for topic in cluster.topics : topic.deletion_policy], [for acl in cluster.acls : acl.deletion_policy]) : contains(["DELETE", "PREVENT", "ABANDON"], policy)
      ]
    ]))
    error_message = "Kafka deletion_policy values must be DELETE, PREVENT, or ABANDON."
  }
}

module "kafka" {
  source = "./modules/kafka"
  count  = var.kafka.enabled ? 1 : 0

  infrastructure_project_id = var.infrastructure_project_id
  platform_project_id       = var.platform_project_id
  environment               = var.environment
  region                    = var.region
  kafka                     = var.kafka
}

output "kafka_clusters" {
  description = "Managed Kafka cluster resource names"
  value       = var.kafka.enabled ? module.kafka[0].clusters : {}
}
