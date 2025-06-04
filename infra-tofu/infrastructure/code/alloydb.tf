variable "alloydb" {
  description = "AlloyDB configuration"
  type = object({
    enabled           = bool
    allowed_ip_ranges = list(string)
    clusters = map(object({
      cpus = number
    }))
  })
}

module "alloydb" {
  source = "./modules/alloydb"
  count  = var.alloydb.enabled ? 1 : 0

  infrastructure_project_id = var.infrastructure_project_id
  platform_project_id       = var.platform_project_id
  environment               = var.environment
  region                    = var.region
  alloydb                   = var.alloydb
}

output "alloydb_initial_password" {
  description = "The initial password for AlloyDB"
  value       = var.alloydb.enabled ? module.alloydb[0].initial_password : null
  sensitive   = true
}