param(
  [string]$MetricsPath = "data/dashboards/internal_playtest_run_002_metrics.json",
  [string]$ContractPath = "data/dashboards/dashboard_mvp_contract_v1.json",
  [string]$OutputPath = "data/dashboards/dashboard_mvp_snapshot.json"
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

function Require-NumericField {
  param(
    [object]$Object,
    [string]$FieldName
  )

  if (-not ($Object.PSObject.Properties.Name -contains $FieldName)) {
    throw "Missing required metrics field: $FieldName"
  }

  $value = $Object.$FieldName
  if ($null -eq $value -or $value -isnot [ValueType]) {
    throw "Field '$FieldName' must be numeric."
  }

  return [double]$value
}

function Read-OptionalNumericField {
  param(
    [object]$Object,
    [string]$FieldName
  )

  if (-not ($Object.PSObject.Properties.Name -contains $FieldName)) {
    return $null
  }

  $value = $Object.$FieldName
  if ($null -eq $value) {
    return $null
  }
  if ($value -isnot [ValueType]) {
    throw "Field '$FieldName' must be numeric when provided."
  }

  return [double]$value
}

Assert-FileExists -Path $MetricsPath -Description "Metrics file"
Assert-FileExists -Path $ContractPath -Description "Contract file"

$metrics = Read-JsonFile -Path $MetricsPath
$contract = Read-JsonFile -Path $ContractPath

$playtestSource = $contract.sources | Where-Object { $_.source_id -eq "playtest_metrics_json" }
if ($null -eq $playtestSource) {
  throw "Contract missing source 'playtest_metrics_json'."
}

foreach ($field in $playtestSource.required_fields) {
  if (-not ($metrics.PSObject.Properties.Name -contains $field)) {
    throw "Metrics file missing required field from contract: $field"
  }
}

$targetMoves = Require-NumericField -Object $metrics -FieldName "target_moves_per_run"
$earlyGameoverRate = Require-NumericField -Object $metrics -FieldName "observed_early_gameover_rate"
$observedAvgMoves = Require-NumericField -Object $metrics -FieldName "observed_avg_moves_per_run"
$avgSessionMinutes = Require-NumericField -Object $metrics -FieldName "avg_session_minutes"
$comboMoveRate = Require-NumericField -Object $metrics -FieldName "combo_move_rate"
$rewardedOptInRate = Require-NumericField -Object $metrics -FieldName "rewarded_opt_in_rate"
$sampleSize = [int](Require-NumericField -Object $metrics -FieldName "sample_size_sessions")
$lineClearRate = $null
if ($metrics.PSObject.Properties.Name -contains "line_clear_rate" -and $null -ne $metrics.line_clear_rate) {
  $lineClearRate = [double]$metrics.line_clear_rate
}
$opsAlertCount = Read-OptionalNumericField -Object $metrics -FieldName "ops_alert_count"
$opsAlertCriticalCount = Read-OptionalNumericField -Object $metrics -FieldName "ops_alert_critical_count"
$opsRuntimeErrorSessions = Read-OptionalNumericField -Object $metrics -FieldName "ops_runtime_error_sessions"
$opsEarlyGameoverAlertRate = Read-OptionalNumericField -Object $metrics -FieldName "ops_early_gameover_alert_rate"

if ($null -ne $opsAlertCount -and $opsAlertCount -lt 0) { $opsAlertCount = $null }
if ($null -ne $opsAlertCriticalCount -and $opsAlertCriticalCount -lt 0) { $opsAlertCriticalCount = $null }
if ($null -ne $opsRuntimeErrorSessions -and $opsRuntimeErrorSessions -lt 0) { $opsRuntimeErrorSessions = $null }
if ($null -ne $opsEarlyGameoverAlertRate -and $opsEarlyGameoverAlertRate -lt 0) { $opsEarlyGameoverAlertRate = $null }

if ($targetMoves -le 0) { throw "target_moves_per_run must be > 0." }
if ($sampleSize -le 0) { throw "sample_size_sessions must be > 0." }
if ($earlyGameoverRate -lt 0 -or $earlyGameoverRate -gt 1) { throw "observed_early_gameover_rate must be in [0..1]." }
if ($comboMoveRate -lt 0 -or $comboMoveRate -gt 1) { throw "combo_move_rate must be in [0..1]." }
if ($rewardedOptInRate -lt 0 -or $rewardedOptInRate -gt 1) { throw "rewarded_opt_in_rate must be in [0..1]." }
if ($avgSessionMinutes -lt 0) { throw "avg_session_minutes must be >= 0." }
if ($observedAvgMoves -lt 0) { throw "observed_avg_moves_per_run must be >= 0." }
if ($null -ne $lineClearRate -and ($lineClearRate -lt 0 -or $lineClearRate -gt 1)) { throw "line_clear_rate must be in [0..1] when provided." }
if ($null -ne $opsAlertCount -and $opsAlertCount -lt 0) { throw "ops_alert_count must be >= 0 when provided." }
if ($null -ne $opsAlertCriticalCount -and $opsAlertCriticalCount -lt 0) { throw "ops_alert_critical_count must be >= 0 when provided." }
if ($null -ne $opsRuntimeErrorSessions -and $opsRuntimeErrorSessions -lt 0) { throw "ops_runtime_error_sessions must be >= 0 when provided." }
if ($null -ne $opsEarlyGameoverAlertRate -and ($opsEarlyGameoverAlertRate -lt 0 -or $opsEarlyGameoverAlertRate -gt 1)) { throw "ops_early_gameover_alert_rate must be in [0..1] when provided." }

$gapToTarget = [math]::Round(($targetMoves - $observedAvgMoves), 2)
$targetAttainmentPct = [math]::Round((($observedAvgMoves / $targetMoves) * 100), 1)
$sessionDurationScore = [math]::Min(1.0, ($avgSessionMinutes / 10.0))
$sessionQualityComposite = [math]::Round(
  (($comboMoveRate * 40.0) + ($sessionDurationScore * 40.0) + ((1.0 - $earlyGameoverRate) * 20.0)),
  1
)

$snapshot = [ordered]@{
  generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
  contract_version = $contract.contract_version
  source = [ordered]@{
    metrics_path = $MetricsPath
    contract_path = $ContractPath
    sample_size_sessions = $sampleSize
    collection_window_start_utc = $metrics.collection_window_start_utc
    collection_window_end_utc = $metrics.collection_window_end_utc
  }
  blocks = [ordered]@{
    retention_proxy = [ordered]@{
      target_moves_per_run = [math]::Round($targetMoves, 2)
      observed_avg_moves_per_run = [math]::Round($observedAvgMoves, 2)
      gap_to_target_moves = $gapToTarget
      target_attainment_pct = $targetAttainmentPct
      observed_early_gameover_rate = [math]::Round($earlyGameoverRate, 3)
    }
    session_quality = [ordered]@{
      avg_session_minutes = [math]::Round($avgSessionMinutes, 2)
      combo_move_rate = [math]::Round($comboMoveRate, 3)
      line_clear_rate = if ($null -eq $lineClearRate) { $null } else { [math]::Round($lineClearRate, 3) }
      session_quality_composite_score = $sessionQualityComposite
    }
    monetization_proxy = [ordered]@{
      rewarded_opt_in_rate = [math]::Round($rewardedOptInRate, 3)
      ad_mode = "ad_free"
      iap_rollout_strategy = "cosmetics_first"
    }
    engagement_systems = [ordered]@{
      daily_goals_completion_rate = $null
      streak_distribution = $null
      note = "Populate from daily_goal_progress and streak_updated events in analytics pipeline."
    }
    experiment_monitoring = [ordered]@{
      ab_experiment_exposure_count = $null
      variant_split = $null
      note = "Populate from ab_experiment_exposure event aggregates."
    }
    observability_alerting = [ordered]@{
      ops_alert_count = if ($null -eq $opsAlertCount) { $null } else { [int][math]::Round($opsAlertCount, 0) }
      ops_alert_critical_count = if ($null -eq $opsAlertCriticalCount) { $null } else { [int][math]::Round($opsAlertCriticalCount, 0) }
      ops_runtime_error_sessions = if ($null -eq $opsRuntimeErrorSessions) { $null } else { [int][math]::Round($opsRuntimeErrorSessions, 0) }
      ops_early_gameover_alert_rate = if ($null -eq $opsEarlyGameoverAlertRate) { $null } else { [math]::Round($opsEarlyGameoverAlertRate, 3) }
      note = "Populate from ops_session_snapshot + ops_alert_triggered aggregates."
    }
  }
  notes = @(
    "Dashboard MVP snapshot generated from compact playtest metrics.",
    "Retention/session/monetization blocks are numeric; engagement/experiment blocks are source-ready placeholders until pipeline aggregation is attached."
  )
}

$outputDir = Split-Path -Path $OutputPath -Parent
if (-not [string]::IsNullOrWhiteSpace($outputDir) -and -not (Test-Path $outputDir)) {
  New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

$snapshot | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Dashboard MVP snapshot exported to: $OutputPath"
