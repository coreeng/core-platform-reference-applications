terraform {
  required_version = ">= 1.9.1"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.38.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.38.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}