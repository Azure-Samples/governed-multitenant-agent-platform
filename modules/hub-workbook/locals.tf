# Single source of truth for the governed fleet rendered on the hub dashboard.
# To onboard a business unit, add ONE entry to local.spokes (key, label, ws, sub):
#   - all 18 "regular" AppGenAIContent tiles fan out over it automatically via genai_union_arms
#   - the BU dropdown and the bespoke / cross-workspace tiles reference these ids by token (main.tf)
# The 16 bespoke tiles (kpi, rollup, signal-health, gateway pair, etc.) are per-signal unions,
# not a uniform arm shape, so a new BU still needs a hand-added arm there. Order is bu1, bu2
# to keep the rendered queries byte-stable against the authored baseline.
locals {
  spokes = [
    { key = "bu1", label = "Business unit 1", ws = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-prod/providers/microsoft.operationalinsights/workspaces/law-bu1", sub = "/subscriptions/22222222-2222-2222-2222-222222222222" },
    { key = "bu2", label = "Business unit 2", ws = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-dev/providers/microsoft.operationalinsights/workspaces/law-bu2", sub = "/subscriptions/33333333-3333-3333-3333-333333333333" },
  ]
  hub_sub = "/subscriptions/11111111-1111-1111-1111-111111111111"

  spoke_by_key = { for s in local.spokes : s.key => s }

  # 18 regular tiles interpolate this one expression, so a new spoke appears in all of them at once.
  genai_union_arms = join(", ", [for s in local.spokes : "(workspace('${s.ws}').AppGenAIContent | extend Company='${s.label}')"])

  # BU dropdown options generated from the same list. Double jsonencode: inner builds the option
  # array, outer escapes it so it can sit as the jsonData string value inside the workbook JSON.
  company_options = jsonencode(jsonencode(concat(
    [{ value = "All", label = "All BUs (fleet)", selected = true }],
    [for s in local.spokes : { value = s.label, label = "${s.label} - sub ${substr(s.sub, 15, 8)}" }]
  )))
}
