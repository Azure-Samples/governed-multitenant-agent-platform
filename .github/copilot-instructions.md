# Repo context for GitHub Copilot

This repository is the **public reference implementation** for the Azure Architecture Center
article "Build and govern AI agents across a multitenant organization." It is a
**synthetic-data demo — no customer data, ever.**

It is Terraform (Azure Verified Modules) that stands up a governed AI-agent runtime and stamps it
into spoke tenants: an Azure API Management AI gateway (adopted in production from
`Azure/terraform-ai-gateway-landing-zone`, pinned — never fork or copy it in), an Open Policy Agent
(OPA) policy decision point, a Model Context Protocol (MCP) governed-read tool, an immutable
artifact registry, and a telemetry/audit/ROI rollup. This is the sanitized **one-hub + one-spoke**
subset; multi-tenant fan-out and extra spokes are intentionally excluded.

## Layout

- `stacks/hub` — deploy once: Log Analytics, WORM audit storage, governance workbook, alerts,
  Azure Lighthouse rollup.
- `stacks/spoke-harness` — one spoke: MCP tool host, OPA policy engine (PDP/PEP), spoke telemetry;
  optional integration with the R1 gateway accelerator.
- `modules/` — AVM-style local modules (`hub-workbook`, `hub-alerts`, `lighthouse-delegation`,
  `mcp-tool`, `policy-engine`, `policy`, `purview`, `api-center`, `apim-ai-gateway`).
- `policy/` — `authz.rego` (OPA PDP) and `agt-policy.yaml` (AGT).

## Rules

- **Placeholders only.** Every tenant ID, subscription ID, object ID, workspace GUID, and resource
  name is a documented placeholder wired through a Terraform variable. Never introduce a real value.
  Public Azure built-in role/policy definition GUIDs are intentional and stay as-is.
- **Never commit secrets or state.** `.gitignore` blocks `*.tfstate` and `*.tfvars`; the allowed
  non-secret examples are the per-stack `*.tfvars.example` files.
- **Pin everything.** Every AVM module (`Azure/avm-res-*`) has an exact version; the adopted
  accelerator is commit-pinned.
- **Label preview services as preview:** Microsoft Agent 365, Microsoft Entra Tenant Governance, and
  the Azure API Management dedicated AI Gateway tier.
- Favor simplicity; comment any choice that isn't production best practice.
- Component IDs (A-2.3, B-2.3, X-3, ...) trace to the article as the source of truth; see the
  Component ID mapping in `README.md`.
