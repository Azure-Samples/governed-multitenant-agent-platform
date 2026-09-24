# Policy-as-code for the Agent Factory Policy Decision Point (A-1.3), served by OPA.
# Hierarchy the customer requires: enterprise (non-overridable) -> BU -> team -> agent.
# Lower levels may only ADD restrictions, never remove an enterprise one.
# Fail-closed: anything not explicitly allowed is denied (the gateway PEP treats a missing
# or false result as a 403).
package http.authz

default allow := false

# Enterprise guardrail (non-overridable): never allow the admin path, regardless of BU/team/agent.
enterprise_denied if input.path == "/admin"

# A recognized clearance is required for a governed read (separate rules instead of the
# `in` keyword, for broad OPA-version compatibility).
valid_clearance if input.clearance == "public"
valid_clearance if input.clearance == "internal"
valid_clearance if input.clearance == "restricted"

# Governed SOP read (A-1.3): a POST that clears the enterprise guardrail and carries a
# recognized clearance. A missing or invalid clearance falls through to deny (fail-closed).
allow if {
	not enterprise_denied
	input.method == "POST"
	input.action == "read_sops"
	valid_clearance
}

# Backward-compatible allow for other governed POST calls (e.g. the gateway PEP) that do
# not carry an action field. Real BU/team/agent rules layer on top and can only restrict.
allow if {
	not enterprise_denied
	input.method == "POST"
	not input.action
}
