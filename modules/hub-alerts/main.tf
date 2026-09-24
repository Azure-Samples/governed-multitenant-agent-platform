# Hub-side alerting for the federated agent fleet: an action group, two cross-workspace
# scheduled-query alerts (fleet token spend, fleet reliability), and a subscription budget.
#
# CAVEAT (validate before relying on it): the scheduled-query rules read the delegated spoke
# workspaces cross-workspace via workspace('...') over Azure Lighthouse. Cross-tenant firing
# for Log alerts over Lighthouse must be confirmed after the first clean 200 flows; if a
# spoke's data does not resolve from the hub rule context, deploy the same rule inside that
# spoke (spoke-harness) instead. The subscription budget below is hub-local and always works.

locals {
  genai_union = join(",\n  ", [for w in var.spoke_workspace_ids : "(workspace('${w}').AppGenAIContent)"])
  exc_union   = join(",\n  ", [for w in var.spoke_workspace_ids : "(workspace('${w}').AppExceptions)"])

  # Same spoke AppGenAIContent union, but each arm tagged with a friendly BU name so the
  # per-tenant alert can group by tenant and name the one that runs away.
  genai_union_labeled = join(",\n  ", [for w in var.spoke_workspace_ids : "(workspace('${w}').AppGenAIContent | extend spokeTenant='${lookup(var.spoke_bu_labels, w, element(split("/", w), length(split("/", w)) - 1))}')"])

  # Same for AppExceptions, tagged per spoke so the reliability alert can name the spoke.
  exc_union_labeled = join(",\n  ", [for w in var.spoke_workspace_ids : "(workspace('${w}').AppExceptions | extend spokeTenant='${lookup(var.spoke_bu_labels, w, element(split("/", w), length(split("/", w)) - 1))}')"])

  # Fleet token spend today with context: total tokens today, yesterday's baseline, the
  # ratio, and the top-contributing spoke and agent (so a fired alert is self-explanatory).
  token_query = <<-KQL
    let tok = union isfuzzy=true
    ${local.genai_union_labeled}
    | where TimeGenerated > ago(2d)
    | extend tk = toint(Attributes['gen_ai.usage.input_tokens']) + toint(Attributes['gen_ai.usage.output_tokens']);
    let ytotal = toscalar(tok | where TimeGenerated <= ago(1d) | summarize v = sum(tk));
    let topSpokeVal = toscalar(tok | where TimeGenerated > ago(1d) | summarize s = sum(tk) by spokeTenant | top 1 by s | project spokeTenant);
    let topAgentVal = toscalar(tok | where TimeGenerated > ago(1d) | summarize a = sum(tk) by AgentName | top 1 by a | project AgentName);
    tok
    | where TimeGenerated > ago(1d)
    | summarize fleetTokensToday = sum(tk)
    | extend baselineYesterday = coalesce(ytotal, long(0))
    | extend vsBaseline = round(todouble(fleetTokensToday) / max_of(todouble(coalesce(ytotal, long(0))), 1.0), 1)
    | extend topSpoke = topSpokeVal, topAgent = topAgentVal
    | project fleetTokensToday, baselineYesterday, vsBaseline, topSpoke, topAgent
  KQL

  # Per-spoke reliability with context: each spoke's last-hour exception count (exceptionsLastHour),
  # its dominant problem (ProblemId), its 24h baseline rate + trend, its recent agent token activity,
  # and a plain-English summary sentence. Fires per spoke (dimension) so the alert names the culprit.
  exception_query = <<-KQL
    let exc = union isfuzzy=true
    ${local.exc_union_labeled}
    | where TimeGenerated > ago(24h);
    let toks = union isfuzzy=true
    ${local.genai_union_labeled}
    | where TimeGenerated > ago(24h)
    | extend tk = toint(Attributes['gen_ai.usage.input_tokens']) + toint(Attributes['gen_ai.usage.output_tokens'])
    | summarize activityTokens24h = sum(tk) by spokeTenant;
    let cur = exc | where TimeGenerated > ago(1h) | summarize exceptionsLastHour = count() by spokeTenant;
    let prob = exc | where TimeGenerated > ago(1h) | summarize c = count() by spokeTenant, ProblemId | summarize arg_max(c, ProblemId) by spokeTenant | project spokeTenant, topProblem = ProblemId;
    let base = exc | where TimeGenerated <= ago(1h) | summarize priorCount = count() by spokeTenant;
    cur
    | join kind=leftouter prob on spokeTenant
    | join kind=leftouter base on spokeTenant
    | join kind=leftouter toks on spokeTenant
    | extend baselinePerHour = round(todouble(coalesce(priorCount, 0)) / 23.0, 1)
    | extend vsBaseline = round(todouble(exceptionsLastHour) / max_of(baselinePerHour, 1.0), 1)
    | extend trend = case(vsBaseline >= 2.0, 'SPIKING', vsBaseline >= 1.2, 'rising', vsBaseline <= 0.8, 'easing', 'steady')
    | extend activityTokens24h = coalesce(activityTokens24h, long(0))
    | extend summary = strcat(spokeTenant, ': ', tostring(exceptionsLastHour), ' agent exceptions in the last hour (', trend, ' vs a ', tostring(baselinePerHour), '/hr baseline). Top problem: ', topProblem, iff(activityTokens24h > 0, strcat('. This spoke used ', tostring(activityTokens24h), ' agent tokens in the last 24h.'), '.'))
    | project spokeTenant, exceptionsLastHour, topProblem, trend, vsBaseline, baselinePerHour, activityTokens24h, summary
    | order by exceptionsLastHour desc
  KQL

  # Per-tenant token spend: total daily tokens per tagged spoke. The alert criteria thresholds
  # spokeDailyTokens per spokeTenant dimension, so the portal condition reads
  # "spokeDailyTokens > <budget>" and each breaching tenant is named.
  spoke_token_query = <<-KQL
    union isfuzzy=true
    ${local.genai_union_labeled}
    | where TimeGenerated > ago(1d)
    | extend tok = toint(Attributes['gen_ai.usage.input_tokens']) + toint(Attributes['gen_ai.usage.output_tokens'])
    | summarize spokeDailyTokens = sum(tok) by spokeTenant
  KQL
}

resource "azurerm_monitor_action_group" "hub" {
  name                = "ag-agentfactory-hub"
  resource_group_name = var.resource_group_name
  short_name          = "agentfac"
  tags                = var.tags

  email_receiver {
    name                    = "owner"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

# Fleet token-spend guard: fires when a day's total tokens across all governed spokes exceed
# the threshold (a runaway-agent / prompt-loop / cost-spike early warning).
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "token_spend" {
  name                    = "alert-fleet-token-spend"
  description             = "Cost guard (whole fleet). Fires when the governed fleet's total tokens today exceed the daily cap (condition: fleetTokensToday > threshold). The alert names the top-contributing spoke and agent (specification capability) and compares today's spend to yesterday's baseline. Reads spoke AppGenAIContent cross-workspace over Lighthouse."
  resource_group_name     = var.resource_group_name
  location                = var.location
  evaluation_frequency    = "PT1H"
  window_duration         = "P2D"
  scopes                  = [var.log_analytics_workspace_resource_id]
  severity                = 2
  auto_mitigation_enabled = true
  tags                    = var.tags

  criteria {
    query                   = local.token_query
    time_aggregation_method = "Total"
    metric_measure_column   = "fleetTokensToday"
    threshold               = var.token_daily_threshold
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.hub.id]
  }
}

# Fleet reliability guard: fires when agent-layer exceptions across all governed spokes spike
# within an hour.
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "exception_spike" {
  name                    = "alert-fleet-exception-spike"
  description             = "Reliability guard (per subsidiary). Fires when any single spoke's agent-layer exceptions in the last hour exceed the floor (condition: exceptionsLastHour > threshold, split by spoke). The alert names the spoke and its dominant problem (ProblemId), compares the last hour to that spoke's own 24-hour baseline (trend: spiking / rising / steady / easing), and includes the spoke's 24h agent token activity plus a plain-English summary. Reads spoke AppExceptions cross-workspace over Lighthouse."
  resource_group_name     = var.resource_group_name
  location                = var.location
  evaluation_frequency    = "PT1H"
  window_duration         = "P1D"
  scopes                  = [var.log_analytics_workspace_resource_id]
  severity                = 1
  auto_mitigation_enabled = true
  tags                    = var.tags

  criteria {
    query                   = local.exception_query
    time_aggregation_method = "Maximum"
    metric_measure_column   = "exceptionsLastHour"
    threshold               = var.exception_hourly_threshold
    operator                = "GreaterThan"

    dimension {
      name     = "spokeTenant"
      operator = "Include"
      values   = ["*"]
    }

    dimension {
      name     = "topProblem"
      operator = "Include"
      values   = ["*"]
    }

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.hub.id]
  }
}

# Per-tenant token-spend guard: fires and NAMES the specific spoke tenant whose daily tokens
# cross its own budget, catching one runaway subsidiary even when the fleet total looks fine.
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "spoke_token_spend" {
  name                    = "alert-spoke-token-spend"
  description             = "Cost guard (per subsidiary). Fires when any single spoke's tokens today exceed its own daily budget, even when the fleet total looks fine (condition: spokeDailyTokens > threshold, split by spoke). Names the specific spoke. Reads each spoke AppGenAIContent cross-workspace over Lighthouse."
  resource_group_name     = var.resource_group_name
  location                = var.location
  evaluation_frequency    = "PT1H"
  window_duration         = "P1D"
  scopes                  = [var.log_analytics_workspace_resource_id]
  severity                = 2
  auto_mitigation_enabled = true
  tags                    = var.tags

  criteria {
    query                   = local.spoke_token_query
    time_aggregation_method = "Maximum"
    metric_measure_column   = "spokeDailyTokens"
    threshold               = var.spoke_token_daily_threshold
    operator                = "GreaterThan"

    dimension {
      name     = "spokeTenant"
      operator = "Include"
      values   = ["*"]
    }

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.hub.id]
  }
}

# Hub subscription budget: FinOps guardrail with actual (80%) and forecasted (100%) alerts.
resource "azurerm_consumption_budget_subscription" "hub" {
  name            = "budget-agentfactory-hub"
  subscription_id = "/subscriptions/${var.subscription_id}"
  amount          = var.monthly_budget_usd
  time_grain      = "Monthly"

  time_period {
    start_date = var.budget_start_date
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = [var.alert_email]
  }
}
