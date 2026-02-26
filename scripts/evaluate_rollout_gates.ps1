param(
  [string]$MetricsPath = "data/dashboards/internal_playtest_run_002_metrics.json",
  [string]$ThresholdsPath = "data/dashboards/rollout_gates_thresholds_v1.json",
  [string]$OutputPath = "data/dashboards/rollout_gates_report.json"
)

$ErrorActionPreference = "Stop"

function Assert-FileExists {
  param(
    [string]$Path,
    [string]$Description
  )

  if (-not (Test-Path $Path)) {
    throw "$Description not found: $Path"
  }
}

function Read-JsonFile {
  param([string]$Path)
  return Get-Content -Path $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Get-NumericMetric {
  param(
    [object]$Object,
    [string]$Name,
    [bool]$Required = $true
  )

  if (-not ($Object.PSObject.Properties.Name -contains $Name)) {
    if ($Required) {
      throw "Missing required metric: $Name"
    }
    return $null
  }

  $value = $Object.$Name
  if ($null -eq $value) {
    if ($Required) {
      throw "Metric '$Name' is null."
    }
    return $null
  }

  if ($value -isnot [ValueType]) {
    throw "Metric '$Name' must be numeric."
  }

  return [double]$value
}

function New-GateResult {
  param(
    [string]$GateId,
    [string]$Severity,
    [string]$Metric,
    [string]$Comparator,
    [double]$Threshold,
    [Nullable[double]]$Observed,
    [bool]$Passed,
    [string]$Reason
  )

  return [ordered]@{
    gate_id = $GateId
    severity = $Severity
    metric = $Metric
    comparator = $Comparator
    threshold = [math]::Round($Threshold, 6)
    observed = if ($null -eq $Observed) { $null } else { [math]::Round($Observed, 6) }
    status = if ($Passed) { "pass" } else { "fail" }
    reason = $Reason
  }
}

function Evaluate-MinGate {
  param(
    [string]$GateId,
    [string]$Severity,
    [string]$Metric,
    [double]$Threshold,
    [Nullable[double]]$Observed
  )

  if ($null -eq $Observed) {
    return New-GateResult -GateId $GateId -Severity $Severity -Metric $Metric -Comparator ">=" -Threshold $Threshold -Observed $null -Passed $false -Reason "missing metric value"
  }
  $passed = $Observed -ge $Threshold
  $reason = if ($passed) { "ok" } else { "observed value is below threshold" }
  return New-GateResult -GateId $GateId -Severity $Severity -Metric $Metric -Comparator ">=" -Threshold $Threshold -Observed $Observed -Passed $passed -Reason $reason
}

function Evaluate-MaxGate {
  param(
    [string]$GateId,
    [string]$Severity,
    [string]$Metric,
    [double]$Threshold,
    [Nullable[double]]$Observed
  )

  if ($null -eq $Observed) {
    return New-GateResult -GateId $GateId -Severity $Severity -Metric $Metric -Comparator "<=" -Threshold $Threshold -Observed $null -Passed $false -Reason "missing metric value"
  }
  $passed = $Observed -le $Threshold
  $reason = if ($passed) { "ok" } else { "observed value exceeded threshold" }
  return New-GateResult -GateId $GateId -Severity $Severity -Metric $Metric -Comparator "<=" -Threshold $Threshold -Observed $Observed -Passed $passed -Reason $reason
}

Assert-FileExists -Path $MetricsPath -Description "Metrics file"
Assert-FileExists -Path $ThresholdsPath -Description "Thresholds file"

$metrics = Read-JsonFile -Path $MetricsPath
$thresholds = Read-JsonFile -Path $ThresholdsPath

$targetMoves = Get-NumericMetric -Object $metrics -Name "target_moves_per_run" -Required $true
$observedAvgMoves = Get-NumericMetric -Object $metrics -Name "observed_avg_moves_per_run" -Required $true
$observedEarlyGameoverRate = Get-NumericMetric -Object $metrics -Name "observed_early_gameover_rate" -Required $true
$avgSessionMinutes = Get-NumericMetric -Object $metrics -Name "avg_session_minutes" -Required $true
$comboMoveRate = Get-NumericMetric -Object $metrics -Name "combo_move_rate" -Required $true
$sampleSizeSessions = Get-NumericMetric -Object $metrics -Name "sample_size_sessions" -Required $true

$opsAlertCount = Get-NumericMetric -Object $metrics -Name "ops_alert_count" -Required $false
$opsAlertCriticalCount = Get-NumericMetric -Object $metrics -Name "ops_alert_critical_count" -Required $false
$opsRuntimeErrorSessions = Get-NumericMetric -Object $metrics -Name "ops_runtime_error_sessions" -Required $false
$opsEarlyGameoverAlertRate = Get-NumericMetric -Object $metrics -Name "ops_early_gameover_alert_rate" -Required $false

$targetAttainmentPct = $null
if ($targetMoves -gt 0) {
  $targetAttainmentPct = ($observedAvgMoves / $targetMoves) * 100.0
}

$opsAlertRate = $null
if ($null -ne $opsAlertCount -and $sampleSizeSessions -gt 0) {
  $opsAlertRate = $opsAlertCount / $sampleSizeSessions
}

$opsRuntimeErrorSessionRate = $null
if ($null -ne $opsRuntimeErrorSessions -and $sampleSizeSessions -gt 0) {
  $opsRuntimeErrorSessionRate = $opsRuntimeErrorSessions / $sampleSizeSessions
}

$results = New-Object System.Collections.Generic.List[object]

$results.Add(
  (Evaluate-MinGate -GateId "sample_size_sessions_min" -Severity "hard" -Metric "sample_size_sessions" -Threshold ([double]$thresholds.hard.min_sample_size_sessions) -Observed $sampleSizeSessions)
) | Out-Null
$results.Add(
  (Evaluate-MaxGate -GateId "observed_early_gameover_rate_max" -Severity "hard" -Metric "observed_early_gameover_rate" -Threshold ([double]$thresholds.hard.max_observed_early_gameover_rate) -Observed $observedEarlyGameoverRate)
) | Out-Null
$results.Add(
  (Evaluate-MaxGate -GateId "ops_alert_critical_count_max" -Severity "hard" -Metric "ops_alert_critical_count" -Threshold ([double]$thresholds.hard.max_ops_alert_critical_count) -Observed $opsAlertCriticalCount)
) | Out-Null
$results.Add(
  (Evaluate-MaxGate -GateId "ops_runtime_error_session_rate_max" -Severity "hard" -Metric "ops_runtime_error_session_rate" -Threshold ([double]$thresholds.hard.max_ops_runtime_error_session_rate) -Observed $opsRuntimeErrorSessionRate)
) | Out-Null
$results.Add(
  (Evaluate-MaxGate -GateId "ops_early_gameover_alert_rate_max" -Severity "hard" -Metric "ops_early_gameover_alert_rate" -Threshold ([double]$thresholds.hard.max_ops_early_gameover_alert_rate) -Observed $opsEarlyGameoverAlertRate)
) | Out-Null

$results.Add(
  (Evaluate-MinGate -GateId "avg_session_minutes_min" -Severity "soft" -Metric "avg_session_minutes" -Threshold ([double]$thresholds.soft.min_avg_session_minutes) -Observed $avgSessionMinutes)
) | Out-Null
$results.Add(
  (Evaluate-MinGate -GateId "combo_move_rate_min" -Severity "soft" -Metric "combo_move_rate" -Threshold ([double]$thresholds.soft.min_combo_move_rate) -Observed $comboMoveRate)
) | Out-Null
$results.Add(
  (Evaluate-MinGate -GateId "target_attainment_pct_min" -Severity "soft" -Metric "target_attainment_pct" -Threshold ([double]$thresholds.soft.min_target_attainment_pct) -Observed $targetAttainmentPct)
) | Out-Null
$results.Add(
  (Evaluate-MaxGate -GateId "target_attainment_pct_max" -Severity "soft" -Metric "target_attainment_pct" -Threshold ([double]$thresholds.soft.max_target_attainment_pct) -Observed $targetAttainmentPct)
) | Out-Null
$results.Add(
  (Evaluate-MaxGate -GateId "ops_alert_rate_max" -Severity "soft" -Metric "ops_alert_rate" -Threshold ([double]$thresholds.soft.max_ops_alert_rate) -Observed $opsAlertRate)
) | Out-Null

$hardGates = $results | Where-Object { $_.severity -eq "hard" }
$softGates = $results | Where-Object { $_.severity -eq "soft" }
$hardPassed = @($hardGates | Where-Object { $_.status -eq "pass" }).Count
$softPassed = @($softGates | Where-Object { $_.status -eq "pass" }).Count
$hardAllPassed = $hardPassed -eq $hardGates.Count
$softAllPassed = $softPassed -eq $softGates.Count

$decision = "hold_and_iterate"
$decisionReason = "One or more hard gates failed."
if ($hardAllPassed -and $softAllPassed) {
  $decision = "go_rollout_25_percent"
  $decisionReason = "All hard and soft gates passed."
} elseif ($hardAllPassed -and -not $softAllPassed) {
  $decision = "go_rollout_10_percent_watchlist"
  $decisionReason = "Hard gates passed, but one or more soft gates failed."
}

$failingHard = @($hardGates | Where-Object { $_.status -eq "fail" })
$failingSoft = @($softGates | Where-Object { $_.status -eq "fail" })
$followups = @()
if ($failingHard.Count -gt 0) {
  $followups += "Block rollout increase and run config rollback review."
  $followups += "Fix failed hard gates before next soft launch wave."
}
if ($failingSoft.Count -gt 0 -and $failingHard.Count -eq 0) {
  $followups += "Proceed with limited rollout and daily watchlist review."
}
if ($followups.Count -eq 0) {
  $followups += "Proceed with planned rollout step and keep monitoring ops_* signals daily."
}

$report = [ordered]@{
  generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
  thresholds_version = $thresholds.version
  input = [ordered]@{
    metrics_path = $MetricsPath
    thresholds_path = $ThresholdsPath
  }
  summary = [ordered]@{
    hard_gates_total = $hardGates.Count
    hard_gates_passed = $hardPassed
    soft_gates_total = $softGates.Count
    soft_gates_passed = $softPassed
    decision = $decision
    decision_reason = $decisionReason
  }
  derived_metrics = [ordered]@{
    target_attainment_pct = if ($null -eq $targetAttainmentPct) { $null } else { [math]::Round($targetAttainmentPct, 3) }
    ops_alert_rate = if ($null -eq $opsAlertRate) { $null } else { [math]::Round($opsAlertRate, 6) }
    ops_runtime_error_session_rate = if ($null -eq $opsRuntimeErrorSessionRate) { $null } else { [math]::Round($opsRuntimeErrorSessionRate, 6) }
  }
  gates = $results
  next_actions = $followups
}

$outputDir = Split-Path -Path $OutputPath -Parent
if (-not [string]::IsNullOrWhiteSpace($outputDir) -and -not (Test-Path $outputDir)) {
  New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

$report | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Rollout gates report exported to: $OutputPath"
