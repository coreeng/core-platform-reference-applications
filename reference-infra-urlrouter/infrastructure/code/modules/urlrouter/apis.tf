module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "18.1.0"

  project_id = var.infrastructure_project_id

  disable_dependent_services  = false
  disable_services_on_destroy = false

  activate_apis = [
    "certificatemanager.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "storage.googleapis.com",
  ]
}
