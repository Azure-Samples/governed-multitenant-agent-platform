# hub (placeholder)

Observability hub in the Management subscription (hub). To be built:

- Log Analytics workspace (gateway + agent telemetry landing zone).
- Immutable (WORM) audit sink via `avm-res-storage-storageaccount` with a retention /
  legal-hold policy.
- Azure Workbook for the run trace and the illustrative ROI tile.
- Azure Lighthouse delegation to roll up spoke telemetry to the hub.

Maps to (telemetry + audit, ROI). Not yet in the CI/CD matrix.
