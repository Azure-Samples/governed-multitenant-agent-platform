# mcp-tool (R2)

The least-privilege MCP tool (component B-1.2) that hosts the governed, classification-aware
read (B-1.3). Wraps the AVM Container App module (`avm-res-app-containerapp` 0.9.0) with a
system-assigned identity and external ingress.

Status: **infra shell**. Runs a placeholder sample image; the real MCP server and the governed
read logic are blocked on the pilot SOP (due Aug 28). Next: register it as a governed
backend/API in the gateway and grant its identity least-privilege access to the data source.
