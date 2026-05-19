# Terragrunt remote_state is used in terragrunt.hcl to configure remote state configuration
# https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/#remote_state

terraform {
  backend "gcs" {}
}
