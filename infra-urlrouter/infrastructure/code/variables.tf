variable "p2p_version" {
  type        = string
  description = "Version"
}

variable "infrastructure_project_id" {
  type        = string
  description = "Project ID where DBs are"
}

variable "platform_project_id" {
  type        = string
  description = "Core Project ID where K8s is. You get this from Platform Environments repo"
}

variable "environment" {
  type        = string
  description = "Application environment name (eg functional)"
}

variable "region" {
  type        = string
  description = "Region name"
}
