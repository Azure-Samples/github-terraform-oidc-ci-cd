terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.115.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53.1"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.42.0"
    }
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_organisation_target
}

provider "azurerm" {
  features {
    resource_group {
       prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azuread" {
}

data "azurerm_client_config" "current" {}
