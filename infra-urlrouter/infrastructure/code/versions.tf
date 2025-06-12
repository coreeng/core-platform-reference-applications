terraform {
  required_version = ">= 1.9.1"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.39.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.39.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}