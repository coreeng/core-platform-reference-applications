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