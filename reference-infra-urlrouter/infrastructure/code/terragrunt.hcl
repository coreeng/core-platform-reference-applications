terraform_binary             = "tofu"
terraform_version_constraint = ">= 1.10.6"

locals {
  yaml_common = try(yamldecode(file("../common.yaml")), {})
  yaml_config = try(yamldecode(file("../config.yaml")), {})
  config      = merge(local.yaml_common, local.yaml_config)
  p2p_version = get_env("P2P_VERSION")
  environment = get_env("environment")
  tenant_name = get_env("tenant_name")
  app_name    = get_env("app_name")

  # Check if required configuration is present
  has_required_config = alltrue([
    can(local.config.region),
    can(local.config.infrastructure_project_id),
    can(local.config.platform_project_id)
  ])
}

# Skip execution if required configuration is missing
skip = !local.has_required_config

inputs = {
  p2p_version               = local.p2p_version
  region                    = try(local.config.region, null)
  infrastructure_project_id = try(local.config.infrastructure_project_id, null)
  platform_project_id       = try(local.config.platform_project_id, null)
  environment               = local.environment
  urlrouter = try(local.config.urlrouter, {
    enabled = false
    routes  = []
  })
}

remote_state {
  backend = "gcs"

  config = {
    project                   = try(local.config.infrastructure_project_id, null)
    location                  = try(local.config.region, null)
    bucket                    = "tfstate-${try(local.config.infrastructure_project_id, "")}"
    prefix                    = "${try(local.config.infrastructure_project_id, "")}/environments/${local.environment}/tenants/${local.tenant_name}/${local.app_name}/terraform/state"
    enable_bucket_policy_only = true
    gcs_bucket_labels = {
      owner = "terragrunt"
      name  = "terraform_state"
    }
  }
}
