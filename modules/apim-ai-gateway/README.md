# apim-ai-gateway

Governed single entry point. Fronts the model and the MCP tool so there is
no back-door path to execution. Absorbs the runtime policy enforcer, the guardrails
switch-on, and the policy pre-check.

Status: **wires the real AVM module** `Azure/avm-res-apimanagement-service/azurerm` (pinned `0.9.0`).
The wrapper adds the AI Gateway service-level policy, a system-assigned identity, and optional
Log Analytics diagnostics. The `validate-jwt` / `token-limit` / `llm-content-safety` policy
switches are marked TODO in `main.tf` until the identity decision and model backend land.

Definition of done:
1. Unauthorized caller rejected with 403 at gateway entry.
2. `llm-content-safety` on: prompt-injection blocked, output PII redacted.
3. Token-limit enforced, token metrics emitted.
4. Fail-closed on cached policy when the policy source is unreachable.
5. Guardrail latency benchmarked against the 200-300 ms target.
6. Multitenant app token (WIF) validated at the gateway.
