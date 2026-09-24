# Remote state in the hub subscription (hub) storage account.
# Backend values are supplied at init time via -backend-config (CI) or a *.tfbackend file,
# so no account names or keys are committed. See README.md.
terraform {
  backend "azurerm" {
    use_oidc = true
  }
}
