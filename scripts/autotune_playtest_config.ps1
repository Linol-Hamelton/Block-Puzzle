param(
  [Parameter(Mandatory = $true)]
  [string]$MetricsPath,
  [string]$OutputPath = "data/dashboards/internal_playtest_autotuned_config.json",
  [switch]$Strict
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $MetricsPath)) {
  throw "Metrics file not found: $MetricsPath"
}

$raw = Get-Content -Raw $MetricsPath
$m = $raw | ConvertFrom-Json

function Get-Num($value, $fallback) {
  if ($null -eq $value) { return [double]$fallback }
  return [double]$value
}

function Require-NumInRange {
  param(
    [string]$Name,
    [double]$Value,
    [double]$Min,
    [double]$Max
  )
  if ($Value -lt $Min -or $Value -gt $Max) {
    throw "Invalid value for '$Name': $Value. Expected range [$Min, $Max]."
  }
}

function Clamp($value, $min, $max) {
  if ($value -lt $min) { return $min }
  if ($value -gt $max) { return $max }
  return $value
}

$hardWeight = 0.20
$maxHard = 1
$interstitialCooldown = 2
$targetMoves = [int](Get-Num $m.target_moves_per_run 14)

$earlyGameOverRate = Get-Num $m.observed_early_gameover_rate 0.0
$avgMoves = Get-Num $m.observed_avg_moves_per_run 12.0
$avgSessionMinutes = Get-Num $m.avg_session_minutes 7.0
$comboRate = Get-Num $m.combo_move_rate 0.25
$rewardedOptIn = Get-Num $m.rewarded_opt_in_rate 0.25
$sampleSizeSessions = [int](Get-Num $m.sample_size_sessions 0)

if ($Strict) {
  Require-NumInRange -Name "target_moves_per_run" -Value $targetMoves -Min 6 -Max 40
  Require-NumInRange -Name "observed_early_gameover_rate" -Value $earlyGameOverRate -Min 0 -Max 1
  Require-NumInRange -Name "observed_avg_moves_per_run" -Value $avgMoves -Min 0 -Max 250
  Require-NumInRange -Name "avg_session_minutes" -Value $avgSessionMinutes -Min 0 -Max 180
  Require-NumInRange -Name "combo_move_rate" -Value $comboRate -Min 0 -Max 1
  Require-NumInRange -Name "rewarded_opt_in_rate" -Value $rewardedOptIn -Min 0 -Max 1
  if ($sampleSizeSessions -lt 30) {
    throw "sample_size_sessions must be >= 30 for strict mode. Current: $sampleSizeSessions"
  }
}

if ($earlyGameOverRate -gt 0.35) {
  $hardWeight -= 0.08
  $maxHard -= 1
} elseif ($earlyGameOverRate -lt 0.18 -and $avgMoves -gt ($targetMoves + 2)) {
  $hardWeight += 0.05
}

if ($avgMoves -lt ($targetMoves - 2)) {
  $hardWeight -= 0.05
  $maxHard -= 1
  $interstitialCooldown += 1
} elseif ($avgMoves -gt ($targetMoves + 4)) {
  $hardWeight += 0.04
}

if ($avgSessionMinutes -lt 6.0) {
  $hardWeight -= 0.03
  $interstitialCooldown += 1
}

if ($comboRate -lt 0.20) {
  $hardWeight -= 0.03
}

if ($rewardedOptIn -gt 0.45) {
  $interstitialCooldown += 1
}

$hardWeight = [Math]::Round((Clamp $hardWeight 0.05 0.85), 3)
$maxHard = [int](Clamp $maxHard 0 3)
$interstitialCooldown = [int](Clamp $interstitialCooldown 1 6)

$result = [ordered]@{
  generated_at_utc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  source_metrics = [ordered]@{
    observed_early_gameover_rate = $earlyGameOverRate
    observed_avg_moves_per_run = $avgMoves
    avg_session_minutes = $avgSessionMinutes
    combo_move_rate = $comboRate
    rewarded_opt_in_rate = $rewardedOptIn
    target_moves_per_run = $targetMoves
    sample_size_sessions = $sampleSizeSessions
  }
  tuned_config = [ordered]@{
    "difficulty.hard_piece_weight" = $hardWeight
    "difficulty.max_hard_pieces_per_triplet" = $maxHard
    "ads.interstitial_cooldown_rounds" = $interstitialCooldown
    "balance.target_moves_per_run" = $targetMoves
    "balance.observed_avg_moves_per_run" = $avgMoves
    "balance.observed_early_gameover_rate" = $earlyGameOverRate
  }
  notes = @(
    "Apply tuned_config to remote config for next internal build.",
    "Run at least 30 sessions before next autotune iteration.",
    "Rollback if D1 proxy drops by >2 pp."
  )
}

$outDir = Split-Path -Parent $OutputPath
if ($outDir -and -not (Test-Path $outDir)) {
  New-Item -ItemType Directory -Force $outDir | Out-Null
}

$result | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Autotuned config written to: $OutputPath"
