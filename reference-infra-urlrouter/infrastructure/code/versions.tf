terraform {
  required_version = ">= 1.13.1"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "8.6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.1"
    }
  }
}
