# Remote state in the Management subscription (hub) storage account.
# Backend values supplied at init via -backend-config (CI) or a *.tfbackend file.
terraform {
  backend "azurerm" {
    use_oidc = true
  }
}
