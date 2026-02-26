param(
  [string]$MetricsPath = "data/dashboards/internal_playtest_run_002_metrics.json",
  [string]$TunedConfigPath = "data/dashboards/internal_playtest_run_002_tuned_config.json",
  [string]$DashboardContractPath = "data/dashboards/dashboard_mvp_contract_v1.json",
  [string]$DashboardSnapshotPath = "data/dashboards/dashboard_mvp_snapshot.json",
  [string]$RolloutThresholdsPath = "data/dashboards/rollout_gates_thresholds_v1.json",
  [string]$RolloutReportPath = "data/dashboards/rollout_gates_report_iteration_002.json",
  [switch]$SkipTuning,
  [switch]$FailOnHold
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $MetricsPath)) {
  throw "Metrics file not found: $MetricsPath"
}

if (-not $SkipTuning) {
  & (Join-Path $PSScriptRoot "run_002_tuning.ps1") `
    -MetricsPath $MetricsPath `
    -OutputPath $TunedConfigPath
}

& (Join-Path $PSScriptRoot "export_dashboard_mvp_snapshot.ps1") `
  -MetricsPath $MetricsPath `
  -ContractPath $DashboardContractPath `
  -OutputPath $DashboardSnapshotPath

& (Join-Path $PSScriptRoot "evaluate_rollout_gates.ps1") `
  -MetricsPath $MetricsPath `
  -ThresholdsPath $RolloutThresholdsPath `
  -OutputPath $RolloutReportPath

$report = Get-Content -Path $RolloutReportPath -Raw -Encoding UTF8 | ConvertFrom-Json
$decision = $report.summary.decision

Write-Host "Soft launch iteration #2 decision: $decision"
Write-Host "Hard gates: $($report.summary.hard_gates_passed)/$($report.summary.hard_gates_total)"
Write-Host "Soft gates: $($report.summary.soft_gates_passed)/$($report.summary.soft_gates_total)"

if ($FailOnHold -and $decision -eq "hold_and_iterate") {
  throw "Rollout decision is hold_and_iterate."
}
