# Microsoft Purview account (unified data governance: catalog, classification, lineage, DSPM for AI).
#
# There is no published Azure Verified Module for a Purview account in the Terraform registry yet
# (checked 2026-09-02: Azure/avm-res-purview-account/azurerm returns 404). Per the harness IaC
# standard, this is a thin AVM-style wrapper around the azurerm resource: consistent naming, tags,
# system-assigned identity, and clean interfaces. Swap to the AVM module when Microsoft publishes it.
#
# SCOPE: this deploys the Purview ACCOUNT (control plane). The governance CONTENT inside Purview
# (collections, scans, scan rulesets, classifications, data-source registrations, DSPM-for-AI) is
# data-plane configuration performed in the Purview portal or REST API, not Terraform. The M365-side
# protective sensitivity labels and DLP policies are configured in the Microsoft Purview compliance
# portal (Graph / Security and Compliance), also not Azure Terraform.
#
# Example usage:
#   module "purview" {
#     source                 = "../../modules/purview"
#     name                   = "pview-agentfactory-hub"
#     resource_group_name    = module.resource_group.name
#     location               = var.location
#     public_network_enabled = false # sealed posture; add private endpoints to reach it
#     tags                   = local.tags
#   }

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}

resource "azurerm_purview_account" "this" {
  name                        = var.name
  resource_group_name         = var.resource_group_name
  location                    = var.location
  public_network_enabled      = var.public_network_enabled
  managed_resource_group_name = var.managed_resource_group_name

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
