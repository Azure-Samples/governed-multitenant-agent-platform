# modules/policy

Governance-by-construction for the agent platform: a **custom Azure Policy initiative**
(policy set) of built-in definitions, plus an optional **audit-first** subscription
assignment. This is the enforcement layer that makes the fleet dashboard's red posture
tiles (public Foundry endpoints, key auth left on) impossible instead of merely visible.

Thin AVM-style wrapper: there is no published AVM module for a curated custom initiative,
so `azurerm` is wrapped here with pinned providers, consistent naming, and clean interfaces.

## What it maps to

| Concern | Members | Citadel / customer component |
|---|---|---|
| Seal the model backends | Cognitive Services managed identity, disable public network, disable local auth; Foundry model eligibility / approved models | Component 3 + 5, X-2 |
| Keyless + private data | Storage no-shared-key / secure-transfer / min-TLS / no-public; Key Vault soft-delete / RBAC / no-public; AI Search no-public / no-local-auth | Component 2 + 5, X-1 |
| Gateway + runtime hardening | API Management VNet / no-direct-management; Container Apps no public / no external network | A-2.3, B-1.2 |
| Observable by default | Key Vault diagnostics to the hub workspace (opt-in) | C-1.2 |
| Fleet hygiene | Allowed locations (data residency) | C-1.5, data residency |

All GUIDs were verified against the live built-in catalogue on 2026-09-17.

## Audit-first by design

- `audit_effect` defaults to **Audit** (report, block nothing). Raise to **Deny** per tenant
  once findings are clean.
- `configure_effect` (the Cognitive Services remediation members) defaults to **Disabled**
  (inert). Raise to **Modify** to auto-seal public access / local auth.
- `enable_assignment` defaults to **false**: importing/committing the module deploys nothing.
- The diagnostics member is included only when `log_analytics_workspace_id` is set; the
  approved-models member only when `enable_approved_models_policy` is true.
- **Tag enforcement is deliberately excluded.** The built-in "Require a tag on resources" is a
  hardwired **Deny** (no audit variant), so it does not belong in an audit-first set - it blocks
  every untagged resource create/update. Add it as an explicit Deny (with tag remediation) once
  the fleet is clean.

## Federation note

Azure Policy assignments are **per-tenant** - one management-group assignment cannot span the
federated tenants, and Lighthouse grants read rollup, not cross-tenant policy
assignment. The pipeline deploys this same pinned initiative into **each tenant's** scope.

## Recommended alongside (not in this module)

- **Microsoft Cloud Security Benchmark (MCSB)** built-in initiative as the broad baseline.
- **Microsoft Defender for Cloud - Defender for AI Services** plan.

## Example

```hcl
module "policy" {
  source = "../../modules/policy"

  # Audit-only, no assignment (definition only):
  # (defaults are enough)

  # ...or assign audit-only to one subscription:
  enable_assignment          = true
  assignment_subscription_id = "44444444-4444-4444-4444-444444444444"
  assignment_location        = "eastus2"

  # Ship diagnostics to the hub workspace (still Disabled effect until you opt in):
  log_analytics_workspace_id = module.log_analytics.resource_id
}
```

Effects stay Audit-first; flip `audit_effect = "Deny"` / `configure_effect = "Modify"` only
after a burn-in per Citadel's "demonstrate the outcome before expanding."
