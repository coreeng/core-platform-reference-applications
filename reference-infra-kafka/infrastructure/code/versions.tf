terraform {
  required_version = ">= 1.12.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.40.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "7.40.0"
    }
  }
}
