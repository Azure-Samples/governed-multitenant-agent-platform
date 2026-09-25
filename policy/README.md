# Runtime governance policy

Two complementary layers answer "is this action allowed?" at runtime. Both must pass (defense in depth).

## 1. OPA PDP at the gateway (out-of-process, hosted)

- Policy: [`authz.rego`](authz.rego)
- Host: [`modules/policy-engine`](../modules/policy-engine) runs Open Policy Agent on Azure Container Apps.
- Caller: the APIM AI Gateway PEP calls it (`send-request`) on every sensitive action, **fail-closed**.
- This is the network-boundary check. It does not depend on the agent's cooperation, so it holds even
  if the agent is compromised or misbehaving.

## 2. AGT (ACS v5) in the agent runtime (in-process SDK)

- Policy: [`agt-policy.yaml`](agt-policy.yaml)
- Host: **none in this repo.** The Agent Governance Toolkit is an in-process SDK installed into the agent
  runtime (the agent owner's code, e.g. Business unit 1's Foundry / Microsoft Agent Framework agent), not a
  standalone service. AGT ships as pip / npm / NuGet / crate packages (pinned to `v5.0.0`) and uses OPA
  under the covers; it does not publish a runnable policy-server image to host in Terraform.
- What it adds beyond the gateway: per-tool-call policy evaluation, MCP request/response scanning, and
  tamper-evident (hash-chained) audit, closer to the agent than the gateway can reach.
- Audit destination: AGT governance events export to the harness **Event Hub** (provided by
  `stacks/spoke-gateway`) and roll up to the hub **Log Analytics**; correlate with the gateway's
  `correlation-id`.

## Ownership and status

- The security and Purview owner owns the rule content in both files; the versions here are fail-closed starters.
- The AGT side is **Public Preview**: pin the version and state preview status in the demo.
- Validate the AGT bundle with `agt lint-policy policy/` (ACS v5) before relying on it.
