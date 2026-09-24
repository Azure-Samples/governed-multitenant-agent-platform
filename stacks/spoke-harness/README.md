# spoke-harness

The governed harness stamped into each spoke tenant: R1 (APIM AI Gateway) now, with R2 (MCP
tool + governed read), Key Vault, and the Foundry project to follow. Deploys into the
Application subscription (spoke-app); env isolation is resource-group level (dev / prod).

## Local plan

```powershell
cd stacks/spoke-harness
terraform init -backend-config="key=spoke-harness.tfstate" `
  -backend-config="resource_group_name=<state-rg>" `
  -backend-config="storage_account_name=<state-sa>" `
  -backend-config="container_name=tfstate"
terraform plan -var-file=terraform.tfvars
```

Copy `terraform.tfvars.example` to `terraform.tfvars` (git-ignored) and fill in the ids.

## Notes
- OIDC only, no stored secrets. Configuring backend state + repo OIDC variables needs a
  one-time JIT admin request on this EMU repo.
- The AVM APIM module and AI Gateway policy XML are still TODO in `modules/apim-ai-gateway`.
