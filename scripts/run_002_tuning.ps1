param(
  [string]$MetricsPath = "data/dashboards/internal_playtest_run_002_metrics.json",
  [string]$OutputPath = "data/dashboards/internal_playtest_run_002_tuned_config.json"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $MetricsPath)) {
  throw "Metrics file not found: $MetricsPath`nCreate it from template: data/dashboards/internal_playtest_run_002_metrics_template.json"
}

$scriptPath = Join-Path $PSScriptRoot "autotune_playtest_config.ps1"

& $scriptPath `
  -MetricsPath $MetricsPath `
  -OutputPath $OutputPath `
  -Strict

Write-Host "Run 002 tuning complete. Output: $OutputPath"
