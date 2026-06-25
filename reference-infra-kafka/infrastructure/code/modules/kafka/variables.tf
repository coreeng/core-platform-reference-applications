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
}
