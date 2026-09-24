# A-1.3 Policy Engine (PDP). The customer specifies OPA/Cedar; this runs Open Policy
# Agent as a Container App serving allow/deny decisions over its REST API. Thin AVM-style
# wrapper over the AVM Container App module. Ships with OPA's default (empty) policy until
# the Rego bundle (enterprise -> BU -> team -> agent namespaces) is authored; with no policy
# loaded OPA returns no decision, which the gateway PEP treats as deny (fail-closed).

module "containerapp" {
  source  = "Azure/avm-res-app-containerapp/azurerm"
  version = "0.9.0"

  name                                  = var.name
  resource_group_name                   = var.resource_group_name
  container_app_environment_resource_id = var.container_app_environment_resource_id
  location                              = var.location
  revision_mode                         = "Single"
  tags                                  = var.tags

  managed_identities = {
    system_assigned = true
  }

  # The Rego policy bundle, mounted into OPA as a file via a secret volume.
  secrets = {
    authz_rego = {
      name  = "authz-rego"
      value = var.authz_rego
    }
  }

  template = {
    min_replicas = var.min_replicas
    containers = [{
      name   = "opa"
      image  = var.image
      cpu    = 0.25
      memory = "0.5Gi"
      args   = ["run", "--server", "--addr=0.0.0.0:8181", "--log-level=info", "/policies"]
      volume_mounts = [{
        name = "policies"
        path = "/policies"
      }]
    }]
    volumes = [{
      name         = "policies"
      storage_type = "Secret"
      secrets = [{
        path        = "authz.rego"
        secret_name = "authz-rego"
      }]
    }]
  }

  # External for the demo so the (public) APIM gateway can reach the decision API.
  # TODO: make internal and reach it over VNet integration once the networking box lands.
  ingress = {
    external_enabled = true
    target_port      = 8181
    traffic_weight = [{
      latest_revision = true
      percentage      = 100
    }]
  }
}
