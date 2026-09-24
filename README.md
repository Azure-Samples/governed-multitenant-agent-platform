# Governed multitenant AI agent platform — reference implementation (one hub + one spoke)

De-identified Terraform reference implementation for the **governed multitenant AI agent platform**
pattern: author agents from no-code to pro-code, apply one governance model to every agent (one
control plane, platform-specific runtime enforcement, centralized visibility), and deploy build-once
across a federated hub-and-spoke organization.

> **Synthetic data only — no customer data.** This repository contains only demonstration
> infrastructure code and synthetic values. It carries no tenant IDs, subscription IDs, workspace
> IDs, resource names, secrets, or customer identifiers — every environment-specific value is a
> documented placeholder wired through Terraform variables.

## Architecture at a glance

The platform is organized as three planes over a shared data/spec foundation, deployed build-once
across a federation:

- **Control plane (governance)** — registry, spec authoring, policy engine, stage-gated approvals.
- **Execution plane (controls)** — runtime, routing gateway + enforcer, governed MCP tools,
  classification-aware data access; every sensitive action gets a policy pre-check, content-safety
  scan, and clearance check, and a denied action fails closed and is audited.
- **Operations plane (visibility)** — telemetry + immutable (WORM) audit, evaluations, deployment
  and rollback, business value/ROI.
- **Federation** — an infrastructure-as-code factory stamps the identical governance and enforcement
  infrastructure into each tenant; a governing tenant gets delegated views via Azure Lighthouse and
  Microsoft Entra Tenant Governance. Agents, telemetry, audit, and business data stay in each source
  tenant.

## What's in this package

| Path | Role |
| --- | --- |
| `stacks/hub` | Hub stack: resource group, Log Analytics, WORM audit storage, governance workbook, alerts, Lighthouse delegation. |
| `stacks/spoke-harness` | One spoke stack: MCP tool host, policy engine (PDP/PEP), spoke telemetry; optional integration with the R1 gateway accelerator. |
| `modules/hub-workbook` | Azure Monitor Workbook rendered from a fleet list (`locals.tf`) — onboarding a business unit is one config entry. Sample ships two generic BUs (`bu1`, `bu2`). |
| `modules/hub-alerts` | Hub alert rules over spoke telemetry. |
| `modules/lighthouse-delegation` | Azure Lighthouse read-only delegation (Reader, Monitoring Reader) to the governing tenant. |
| `modules/mcp-tool` | Governed Model Context Protocol tool host (Azure Container Apps). |
| `modules/policy-engine` | Policy-as-code decision point (Open Policy Agent) as a scale-to-zero container. |
| `modules/policy` | Azure Policy guardrail initiative (built-in policy definitions, per-tenant assignment). |
| `modules/purview`, `modules/api-center`, `modules/apim-ai-gateway` | Supporting module library for the control/execution planes. |
| `policy/` | Sample policy-as-code bundle (`authz.rego`) and agent governance policy. |

### Component ID mapping

Each included component traces to a component ID in the architecture article (the source of truth):

| Component ID | Article component | Realized by |
| --- | --- | --- |
| A-1.3 / B-2.3 | Policy engine (PDP) / runtime policy enforcer (PEP) | `modules/policy-engine`, `policy/authz.rego` |
| A-2.2 | Capability catalog | `modules/api-center` |
| A-2.3 | Routing and orchestration gateway | `modules/apim-ai-gateway` (production: the adopted AI Gateway Landing Zone accelerator) |
| B-1.2 / B-1.3 | Tool integration (MCP) / classification-aware data access | `modules/mcp-tool` |
| C-1.2 | Telemetry and audit pipeline (WORM) | `stacks/hub` (Log Analytics + immutable audit storage) |
| C-1.5 | Business value and ROI | `modules/hub-workbook`, `stacks/hub/grafana` |
| X-2 | Data classification service | `modules/purview` |
| X-1 / federation | Identity and delegated governance | `modules/lighthouse-delegation` |
| Guardrails (infra) | Azure Policy platform guardrails | `modules/policy` |

### Deliberately excluded from this sample

- The **R1 governed gateway** (APIM AI gateway, Content Safety, API Center catalog, Foundry model
  backend) is provided in production by the published Microsoft **AI Gateway Landing Zone**
  accelerator (`Azure/terraform-ai-gateway-landing-zone`), adopted at a pinned commit rather than
  copied in. `stacks/spoke-harness` integrates with it optionally (`enable_gateway_integration`,
  off by default).
- Additional spokes, connectivity stack, and the multi-tenant policy fan-out stack.

## Preview components

Some building blocks are in public preview at the time of writing — **Microsoft Agent 365**,
**Microsoft Entra Tenant Governance**, and the **Azure API Management dedicated AI Gateway tier**.
Pin versions and validate current availability before you rely on them.

## Placeholders to set

Replace these documented placeholders (via `*.tfvars` / `-backend-config`) with your own values:

| Placeholder | Meaning |
| --- | --- |
| `00000000-0000-0000-0000-000000000000` | Governing/business-unit tenant ID |
| `11111111-1111-1111-1111-111111111111` | Hub subscription ID |
| `22222222-…` / `33333333-…` | Business-unit (spoke) subscription IDs |
| `99999999-…` | Lighthouse delegation principal (group/SPN object) ID |
| `law-bu1` / `law-bu2` | Spoke Log Analytics workspace names |

Remaining GUIDs in `modules/policy` and role assignments are **public Azure built-in policy/role
definition IDs** (for example `acdd72a7-…` = Reader) and are intentionally left as-is.

## Deploy (high level)

Requires Terraform and Azure CLI. Uses AzureRM remote state via OIDC; backend values are supplied at
init, so no account names or keys are committed.

```bash
# 1) Hub
cd stacks/hub
terraform init -backend-config=<your.tfbackend>
terraform apply -var-file=<your.tfvars>

# 2) Spoke (repeat per business unit)
cd ../spoke-harness
cp terraform.tfvars.example terraform.tfvars   # then edit placeholders
terraform init -backend-config=<your.tfbackend>
terraform apply -var-file=terraform.tfvars
```

All Azure resources use published **Azure Verified Modules** (`Azure/avm-res-*`, pinned); modules
this repo authors follow AVM conventions (naming, tags, interfaces).

## Notes

- This sample is for demonstration and portfolio purposes. The engineering assets that accompany the
  Azure Architecture Center article are published through an official Microsoft repository
  (Azure-Samples or `github.com/mspnp`), not a personal repository.
- No warranty. See `LICENSE`.
