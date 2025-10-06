terraform {
  required_version = ">= 1.10.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.50.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.50.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}