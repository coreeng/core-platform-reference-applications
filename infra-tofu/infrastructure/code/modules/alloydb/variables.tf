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