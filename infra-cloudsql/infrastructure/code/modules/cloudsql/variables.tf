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
    enabled           = bool
    allowed_ip_ranges = optional(list(map(string)), [])
    clusters = optional(object({
      postgres = optional(list(object({
        name = string
        tier = string
        databases = list(object({
          name      = string
          charset   = optional(string, "")
          collation = optional(string, "")
        }))
      })))
    }))
  })
}