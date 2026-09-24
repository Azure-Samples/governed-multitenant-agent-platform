# Thin AVM-style wrapper: no AVM module for scheduled-query alerts / consumption budgets
# (registry checked 2026-08-28), so azurerm resources are wrapped here with pinned providers.
terraform {
  required_version = ">= 1.11"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
