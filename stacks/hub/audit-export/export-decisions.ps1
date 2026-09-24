# Hub-side governance audit exporter (the "copy step" into the immutable audit store).
#
# Reads runtime governance decisions from the spoke Log Analytics workspaces cross-tenant
# over Azure Lighthouse and appends them as immutable JSONL records into the hub write-once
# audit container. Re-runnable: each run writes ONE new timestamped blob, so the trail is
# append-only by construction and existing records are never modified.
#
# Identity requirements (uses the caller's Entra login, az login):
#   - Monitoring Reader on the spoke workspaces (granted via the hub Lighthouse group
#     "Agent Platform Hub Telemetry Readers"), and
#   - Storage Blob Data Contributor on the audit storage account (shared-key auth is off).
#
# Network: the audit account is publicNetworkAccess=Disabled in steady state. For a scheduled
# run, host this on a hub compute with a private endpoint into the account. For an operator
# run, temporarily allow the runner's public IP on the account firewall, run, then re-lock.
param(
  [string]$StorageAccount = "stagentfactoryaudit1hnir",
  [string]$Container = "audit",
  [int]$LookbackDays = 90,
  # Spoke workspaces that emit runtime classification decisions from the governed MCP tool.
  # No spoke runs the real tool today; add a workspace GUID here as each spoke goes live.
  [hashtable]$Sources = @{}
)
$ErrorActionPreference = "Stop"

$kql = @"
ContainerAppConsoleLogs_CL
| where TimeGenerated > ago(${LookbackDays}d)
| where Log_s has 'classification_decision'
| extend d = parse_json(substring(Log_s, indexof(Log_s, '{')))
| where tostring(d['classification_decision']) == '1'
| project TimeGenerated,
          tool = tostring(d['tool']),
          classification = tostring(d['label']),
          callerClearance = tostring(d['callerClearance']),
          effect = tostring(d['effect']),
          stage = iff(isempty(tostring(d['stage'])), 'tool', tostring(d['stage']))
| order by TimeGenerated asc
"@

$records = New-Object System.Collections.Generic.List[object]
foreach ($ws in $Sources.Keys) {
  $rows = az monitor log-analytics query -w $ws --analytics-query $kql -o json | ConvertFrom-Json
  foreach ($r in $rows) {
    $records.Add([ordered]@{
        timestamp       = $r.TimeGenerated
        source          = $Sources[$ws]
        tool            = $r.tool
        classification  = $r.classification
        callerClearance = $r.callerClearance
        effect          = $r.effect
        stage           = $r.stage
      })
  }
}

if ($records.Count -eq 0) { Write-Host "No decisions found in the lookback window; nothing written."; return }

$jsonl = ($records | ForEach-Object { $_ | ConvertTo-Json -Compress }) -join "`n"
$stamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
$blobName = "governance-decisions/run-$stamp.jsonl"
$tmp = New-TemporaryFile
Set-Content -Path $tmp -Value $jsonl -NoNewline -Encoding utf8
az storage blob upload --account-name $StorageAccount --container-name $Container --name $blobName `
  --file $tmp --auth-mode login --only-show-errors -o none
Remove-Item $tmp -ErrorAction SilentlyContinue
Write-Host "Wrote $($records.Count) decision records to $StorageAccount/$Container/$blobName"
