terraform {
  required_version = ">= 1.10.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.9.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "7.9.0"
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
