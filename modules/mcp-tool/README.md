# mcp-tool

The least-privilege MCP tool that hosts the governed, classification-aware
read. Wraps the AVM Container App module (`avm-res-app-containerapp` 0.9.0) with a
system-assigned identity and external ingress.

Status: **infra shell**. Runs a placeholder sample image; the real MCP server and the governed
read logic are blocked on the pilot specification (due Aug 28). Next: register it as a governed
backend/API in the gateway and grant its identity least-privilege access to the data source.
