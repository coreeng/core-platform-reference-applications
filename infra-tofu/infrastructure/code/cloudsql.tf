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

module "cloudsql" {
  source = "./modules/cloudsql"
  count  = var.cloudsql.enabled ? 1 : 0

  infrastructure_project_id = var.infrastructure_project_id
  platform_project_id       = var.platform_project_id
  environment               = var.environment
  region                    = var.region
  cloudsql                  = var.cloudsql
}

output "cloudsql_initial_password" {
  description = "The initial password for Cloud SQL"
  value       = var.cloudsql.enabled ? module.cloudsql[0].initial_password : null
  sensitive   = true
}