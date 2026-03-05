# Configure the Azure provider

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }

      azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.1.0"

  backend "http" {
    address        = "https://gitlab.com/api/v4/projects/79708294/terraform/state/default"
    lock_address   = "https://gitlab.com/api/v4/projects/79708294/terraform/state/default/lock"
    unlock_address = "https://gitlab.com/api/v4/projects/79708294/terraform/state/default/lock"
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
  }
}


provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}