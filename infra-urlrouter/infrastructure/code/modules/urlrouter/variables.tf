variable "infrastructure_project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "urlrouter" {
  description = "URL router configuration"
  type = object({
    enabled = bool
    routes = optional(list(object({
      name       = string
      host       = string
      type       = string
      enable_cdn = optional(bool, false)
      endpoints = optional(list(object({
        name                = string
        path                = optional(string, "/")
        path_prefix_rewrite = optional(string)
        host                = string
        port                = optional(number, 443)
        weight              = number
      })))
      bucket = optional(object({
        name       = string
        location   = optional(string)
        labels     = optional(map(string), {})
        enable_cdn = optional(bool, true)
      }))
    })))
  })

  validation {
    condition = (
      var.urlrouter.routes == null ? true : alltrue([
        for route in var.urlrouter.routes :
        contains(["service", "bucket"], route.type)
      ])
    )
    error_message = "Each route type must be either \"service\" or \"bucket\"."
  }

  validation {
    condition = (
      var.urlrouter.routes == null ? true : alltrue([
        for route in var.urlrouter.routes :
        route.type == "bucket"
        ? route.bucket != null
        : (route.endpoints != null && length(route.endpoints) > 0)
      ])
    )
    error_message = "Service routes require at least one endpoint; bucket routes require bucket configuration."
  }
}
