# Thin governance module: a custom Azure Policy initiative (policy set) of built-in
# definitions, plus an optional audit-first subscription assignment. No AVM module exists
# for a curated custom initiative, so azurerm is wrapped here with pinned providers.
terraform {
  required_version = ">= 1.11"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
