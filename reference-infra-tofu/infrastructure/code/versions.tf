terraform {
  required_version = ">= 1.12.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.4.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "8.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.1"
    }
  }
}
