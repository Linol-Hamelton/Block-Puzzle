param(
  [string]$Repo,
  [ValidateSet("8.1", "9", "all")]
  [string]$Sprint = "all",
  [switch]$DryRun,
  [switch]$ExportOnly,
  [string]$ExportPath = "docs/roadmap/11_SPRINT8_1_SPRINT9_GITHUB_ISSUES.md"
)

$ErrorActionPreference = "Stop"
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
  $PSNativeCommandUseErrorActionPreference = $false
}

function Resolve-Repo {
  param([string]$ExplicitRepo)

  if (-not [string]::IsNullOrWhiteSpace($ExplicitRepo)) {
    return $ExplicitRepo
  }

  $detected = gh repo view --json nameWithOwner --jq ".nameWithOwner" 2>$null
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($detected)) {
    throw "Cannot detect repository automatically. Pass -Repo '<owner>/<repo>' or run from a linked git repository."
  }

  return $detected.Trim()
}

function Parse-IssuePlanFile {
  param(
    [string]$Path,
    [string]$SprintTag,
    [string]$SourceDoc
  )

  if (-not (Test-Path -Path $Path)) {
    throw "Issue plan file not found: $Path"
  }

  $issues = New-Object System.Collections.Generic.List[object]
  $lines = Get-Content -Path $Path

  $currentDay = $null
  $currentIssue = $null
  $readingAcceptance = $false

  function Complete-Issue {
    param([object]$Issue)

    if ($null -eq $Issue) {
      return
    }

    if ([string]::IsNullOrWhiteSpace($Issue.Code)) { throw "Issue code is missing in $Path" }
    if ([string]::IsNullOrWhiteSpace($Issue.Title)) { throw "Issue title is missing for $($Issue.Code) in $Path" }
    if ($Issue.Labels.Count -eq 0) { throw "Issue labels are missing for $($Issue.Code) in $Path" }
    if ($Issue.AcceptanceCriteria.Count -eq 0) { throw "Acceptance criteria are missing for $($Issue.Code) in $Path" }

    $issues.Add($Issue) | Out-Null
  }

  foreach ($lineRaw in $lines) {
    $line = $lineRaw.TrimEnd()

    if ($line -match '^### Day (?<day>\d+)$') {
      $currentDay = [int]$Matches["day"]
      continue
    }

    if ($line -match '^Issue `(?<code>[^`]+)`$') {
      Complete-Issue -Issue $currentIssue

      $currentIssue = [PSCustomObject]@{
        Sprint = $SprintTag
        Day = $currentDay
        Code = $Matches["code"]
        Title = $null
        Labels = New-Object System.Collections.Generic.List[string]
        AcceptanceCriteria = New-Object System.Collections.Generic.List[string]
        SourceDoc = $SourceDoc
      }
      $readingAcceptance = $false
      continue
    }

    if ($null -eq $currentIssue) {
      continue
    }

    if ($line -match '^Title:\s*`(?<title>[^`]+)`\s*$') {
      $currentIssue.Title = $Matches["title"]
      continue
    }

    if ($line -match '^Labels:\s*`(?<labels>[^`]+)`\s*$') {
      $labels = $Matches["labels"].Split(",")
      foreach ($label in $labels) {
        $trimmed = $label.Trim()
        if (-not [string]::IsNullOrWhiteSpace($trimmed)) {
          $currentIssue.Labels.Add($trimmed) | Out-Null
        }
      }
      continue
    }

    if ($line -eq "Acceptance Criteria:") {
      $readingAcceptance = $true
      continue
    }

    if ($readingAcceptance) {
      if ($line -match "^- (?<criterion>.+)$") {
        $currentIssue.AcceptanceCriteria.Add($Matches["criterion"].Trim()) | Out-Null
        continue
      }

      if ([string]::IsNullOrWhiteSpace($line)) {
        continue
      }

      $readingAcceptance = $false
    }
  }

  Complete-Issue -Issue $currentIssue
  return $issues
}

function Build-IssueBody {
  param([object]$Issue)

  $bodyLines = @(
    '## Context',
    ('Roadmap execution item from Sprint {0}, Day {1} (`{2}`).' -f $Issue.Sprint, $Issue.Day, $Issue.Code),
    '',
    '## Scope',
    '- Execute the task described in the title.',
    '- Keep implementation aligned with current roadmap and implementation status docs.',
    '- Add/update tests and docs for behavior changes.',
    '',
    '## Acceptance Criteria'
  )

  foreach ($criterion in $Issue.AcceptanceCriteria) {
    $bodyLines += "- [ ] $criterion"
  }

  $bodyLines += ''
  $bodyLines += '## Source'
  $bodyLines += ('- `{0}`' -f $Issue.SourceDoc)

  return ($bodyLines -join "`n")
}

function Export-IssuePackMarkdown {
  param(
    [object[]]$Issues,
    [string]$Path
  )

  $directory = Split-Path -Path $Path -Parent
  if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path -Path $directory)) {
    New-Item -Path $directory -ItemType Directory -Force | Out-Null
  }

  $output = New-Object System.Collections.Generic.List[string]
  $output.Add("# Sprint 8.1 + Sprint 9 GitHub Issue Pack")
  $output.Add("")
  $output.Add('Format: direct copy into GitHub issue editor (`Title / Labels / Body`).')
  $output.Add("")
  $output.Add("Autocreate script:")
  $output.Add('```powershell')
  $output.Add('.\scripts\create_sprint8_1_sprint9_issues.ps1 -Repo "<owner>/<repo>" -Sprint all')
  $output.Add('```')
  $output.Add("")

  $sprintGroups = $Issues | Group-Object Sprint | Sort-Object Name
  foreach ($sprintGroup in $sprintGroups) {
    $output.Add("## Sprint $($sprintGroup.Name)")
    $output.Add("")

    $dayGroups = $sprintGroup.Group | Group-Object Day | Sort-Object { [int]$_.Name }
    foreach ($dayGroup in $dayGroups) {
      $output.Add("### Day $($dayGroup.Name)")
      $output.Add("")

      foreach ($issue in ($dayGroup.Group | Sort-Object Code)) {
        $labelsInline = ($issue.Labels -join ",")
        $body = Build-IssueBody -Issue $issue

        $output.Add(('Issue `{0}`' -f $issue.Code))
        $output.Add(('Title: `{0}`' -f $issue.Title))
        $output.Add(('Labels: `{0}`' -f $labelsInline))
        $output.Add('Body:')
        $output.Add('```md')
        foreach ($bodyLine in ($body -split "`r?`n")) {
          $output.Add($bodyLine)
        }
        $output.Add('```')
        $output.Add('')
      }
    }
  }

  Set-Content -Path $Path -Value $output -Encoding UTF8
}

function New-GitHubIssueFromPlan {
  param(
    [string]$TargetRepo,
    [object]$Issue,
    [switch]$IsDryRun
  )

  $body = Build-IssueBody -Issue $Issue
  $labelArgs = @()
  foreach ($label in $Issue.Labels) {
    $labelArgs += "--label"
    $labelArgs += $label
  }

  if ($IsDryRun) {
    Write-Host "[DRY RUN] gh issue create -R $TargetRepo --title `"$($Issue.Title)`" $($labelArgs -join ' ') --body <generated>"
    return
  }

  $output = $null
  $exitCode = 1
  $raw = ""

  try {
    $output = & gh issue create -R $TargetRepo --title $Issue.Title @labelArgs --body $body 2>&1
    $exitCode = $LASTEXITCODE
    $raw = ($output | Out-String)
  } catch {
    $raw = $_.Exception.Message
    $output = @($raw)
    $exitCode = 1
  }

  if ($exitCode -eq 0) {
    $output | Out-Host
    return
  }

  if ($raw -match "could not add label|not found|Resource not accessible by personal access token") {
    Write-Host "Label application failed for '$($Issue.Title)'. Retrying without labels..."
    $fallbackOutput = $null
    $fallbackExitCode = 1

    try {
      $fallbackOutput = & gh issue create -R $TargetRepo --title $Issue.Title --body $body 2>&1
      $fallbackExitCode = $LASTEXITCODE
    } catch {
      $fallbackOutput = @($_.Exception.Message)
      $fallbackExitCode = 1
    }

    if ($fallbackExitCode -ne 0) {
      $fallbackOutput | Out-Host
      throw "Issue creation failed even without labels: $($Issue.Title)"
    }

    $fallbackOutput | Out-Host
    return
  }

  $output | Out-Host
  throw "Issue creation failed: $($Issue.Title)"
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$s81Doc = "docs/roadmap/09_SPRINT8_1_ISSUE_READY_DAILY.md"
$s9Doc = "docs/roadmap/10_SPRINT9_MODE_HUB_ISSUE_READY_DAILY.md"

$s81Issues = Parse-IssuePlanFile -Path (Join-Path $repoRoot $s81Doc) -SprintTag "8.1" -SourceDoc $s81Doc
$s9Issues = Parse-IssuePlanFile -Path (Join-Path $repoRoot $s9Doc) -SprintTag "9" -SourceDoc $s9Doc

$issues = @()
switch ($Sprint) {
  "8.1" { $issues = @($s81Issues) }
  "9" { $issues = @($s9Issues) }
  default { $issues = @($s81Issues + $s9Issues) }
}

if ($issues.Count -eq 0) {
  throw "No issues found for selected sprint filter: $Sprint"
}

$resolvedExportPath = Join-Path $repoRoot $ExportPath
Export-IssuePackMarkdown -Issues $issues -Path $resolvedExportPath
Write-Host "Issue pack exported: $resolvedExportPath"

if ($ExportOnly) {
  Write-Host "Export-only mode enabled. No GitHub issues were created."
  exit 0
}

$targetRepo = Resolve-Repo -ExplicitRepo $Repo

if (-not $DryRun) {
  gh auth status 1>$null 2>$null
  if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI is not authenticated. Run: gh auth login"
  }
}

foreach ($issue in $issues) {
  New-GitHubIssueFromPlan -TargetRepo $targetRepo -Issue $issue -IsDryRun:$DryRun
}

Write-Host "Processed $($issues.Count) issue(s) for sprint filter: $Sprint"
