variable "urlrouter" {
  description = "URL router configuration"
  type = object({
    enabled = bool
    routes = optional(list(object({
      name = string
      host = string
      endpoints = list(object({
        name   = string
        host   = string
        port   = optional(number, 443)
        weight = number
      }))
    })))
  })
}

module "urlrouter" {
  source = "./modules/urlrouter"
  count  = var.urlrouter.enabled ? 1 : 0

  infrastructure_project_id = var.infrastructure_project_id
  region                    = var.region
  urlrouter                 = var.urlrouter
}

output "urlrouter_ip_address" {
  description = "The IP address of the URL router"
  value       = var.urlrouter.enabled ? module.urlrouter[0].ip_address : null
}

output "urlrouter_dns_authorization_records" {
  description = "The DNS authorization records required to provision managed certificates for the URL router"
  value       = var.urlrouter.enabled ? module.urlrouter[0].dns_authorization_records : null
}