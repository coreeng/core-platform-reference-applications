terraform {
  required_version = ">= 1.13.9"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.12.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "8.12.0"
    }
  }
}
