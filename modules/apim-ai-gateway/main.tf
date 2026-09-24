# R1 - APIM AI Gateway (component A-2.3): the governed single entry point.
# Thin AVM-style wrapper over the published AVM APIM module, adding the AI Gateway policy.
# Absorbs B-2.3 (PEP), B-2.1 (guardrails switch-on), and A-1.3 (policy pre-check).

locals {
  # B-2.3 Runtime Policy Enforcer (PEP): when a PDP URL is supplied, call the external
  # Policy Decision Point (OPA, A-1.3) for an allow/deny decision on every request.
  # Fail-closed: a non-allow result, a missing decision, or an unreachable PDP returns 403.
  pdp_policy_block = var.pdp_url == null ? "" : <<-XML
        <send-request mode="new" response-variable-name="pdpResponse" timeout="5" ignore-error="true">
          <set-url>${var.pdp_url}/v1/data/http/authz/allow</set-url>
          <set-method>POST</set-method>
          <set-header name="Content-Type" exists-action="override">
            <value>application/json</value>
          </set-header>
          <set-body>@{
            return new JObject(new JProperty("input", new JObject(
              new JProperty("method", context.Request.Method),
              new JProperty("path", context.Request.Url.Path),
              new JProperty("correlationId", (string)context.Variables["correlationId"])
            ))).ToString();
          }</set-body>
        </send-request>
        <set-variable name="pdpDeny" value="@{
            var r = (IResponse)context.Variables[&quot;pdpResponse&quot;];
            if (r == null) { return true; }
            try {
              var body = r.Body.As&lt;JObject&gt;(preserveContent: true);
              var allow = body[&quot;result&quot;];
              return allow == null || !((bool)allow);
            } catch { return true; }
        }" />
        <choose>
          <when condition="@((bool)context.Variables[&quot;pdpDeny&quot;])">
            <return-response>
              <set-status code="403" reason="Denied by policy decision point" />
              <set-body>{"error":"denied_by_pdp"}</set-body>
            </return-response>
          </when>
        </choose>
  XML

  # Service-level (global) AI Gateway policy applied to every API.
  # correlation-id is emitted for R4 telemetry. token-limit, llm-content-safety, and
  # validate-jwt are switched on here; the validate-jwt specifics depend on the identity
  # decision (agent vs OBO vs service) and are marked TODO until that lands (needed Aug 25).
  default_gateway_policy_xml = <<-XML
    <policies>
      <inbound>
        <base />
        <!-- Emit a correlation id on every request for R4 telemetry -->
        <set-variable name="correlationId" value="@(context.RequestId.ToString())" />
        <set-header name="x-correlation-id" exists-action="override">
          <value>@((string)context.Variables["correlationId"])</value>
        </set-header>
${local.pdp_policy_block}
        <!-- TODO(identity decision, needed Aug 25): validate-jwt for the multitenant app
             token / workload identity federation. Fail-closed: return 403 when the required
             token or claim is absent (achievable in policy XML, no external PDP). -->
        <!-- TODO: token-limit (per-key) + emit-token-metric once the model backend is wired -->
        <!-- TODO: llm-content-safety (Prompt Shields + PII redaction) once the backend model is wired -->
      </inbound>
      <backend>
        <base />
      </backend>
      <outbound>
        <base />
        <set-header name="x-correlation-id" exists-action="override">
          <value>@((string)context.Variables["correlationId"])</value>
        </set-header>
      </outbound>
      <on-error>
        <base />
      </on-error>
    </policies>
  XML
}

module "apim" {
  source  = "Azure/avm-res-apimanagement-service/azurerm"
  version = "0.9.0"

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_email     = var.publisher_email
  publisher_name      = var.publisher_name
  sku_name            = var.sku_name
  tags                = var.tags

  # System-assigned identity for OAuth / Key Vault / backend auth
  managed_identities = {
    system_assigned = true
  }

  # AI Gateway service-level policy (applies to all APIs)
  policy = {
    xml_content = coalesce(var.gateway_policy_xml, local.default_gateway_policy_xml)
  }

  # Register the model as a governed backend (managed-identity auth is applied at the API policy).
  backends = var.model_backend_url == null ? {} : {
    model = {
      protocol    = "http"
      url         = var.model_backend_url
      resource_id = var.model_backend_resource_id
      description = "Azure AI Services model backend."
    }
  }

  # R4: send gateway telemetry to Log Analytics when a workspace id is supplied
  diagnostic_settings = var.log_analytics_workspace_resource_id == null ? {} : {
    to_law = {
      workspace_resource_id = var.log_analytics_workspace_resource_id
    }
  }

  enable_telemetry = false
}
