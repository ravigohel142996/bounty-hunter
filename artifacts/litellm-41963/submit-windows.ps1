# ============================================================================
# submit-windows.ps1 - publish the litellm #41963 PR from YOUR GitHub (Windows)
# ----------------------------------------------------------------------------
# - Everything on E: (47GB free). C: untouched except already-installed tools.
# - Downloads your verified patch + PR text from YOUR bounty-hunter repo,
#   applies, pushes, opens the PR. Nothing else.
# Prereq: git + gh (you already have both).
# Run:    powershell -ExecutionPolicy Bypass -File E:\submit.ps1
# After:  click "Sign CLA" when the cla-assistant bot comments on the PR.
# ============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$WorkRoot = 'E:\dev\litellm-41963'
$Branch   = 'fix/responses-string-input-normalization'
$PatchUrl = 'https://raw.githubusercontent.com/ravigohel142996/bounty-hunter/arena/01a0b9b5-bounty-hunter/artifacts/litellm-41963/0001-fix-responses-normalize-string-input-to-canonical-li.patch'
$BodyUrl  = 'https://raw.githubusercontent.com/ravigohel142996/bounty-hunter/arena/01a0b9b5-bounty-hunter/artifacts/litellm-41963/PR-BODY.md'

function Have($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

Write-Host '== Checking tools =='
if (-not ((Have 'git') -and (Have 'gh'))) {
  Write-Host '  git or gh missing - install and re-run (see previous instructions).'
  exit 1
}
(git --version)
(gh --version) | Select-Object -First 1

gh auth status 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { gh auth login }
gh auth setup-git
$me = (gh api user --jq .login).Trim()
if (-not $me) { Write-Host '  ERROR: run gh auth login first, then re-run.'; exit 1 }
Write-Host "   GitHub account: @$me"

Write-Host '== [0/5] Live competition re-check (issue #41963) =='
$issue = (gh api repos/BerriAI/litellm/issues/41963) | ConvertFrom-Json
$tl = (gh api "repos/BerriAI/litellm/issues/41963/timeline?per_page=100") | ConvertFrom-Json
$nrefs = @($tl | Where-Object { $_.event -eq 'cross-referenced' -and $_.source.issue.pull_request }).Count
Write-Host "   comments=$($issue.comments)   competing-PR-links=$nrefs"
if ($nrefs -gt 0) {
  Read-Host '   WARNING: a competing PR appeared. Ctrl+C to stop and reassess, or Enter to continue anyway'
}

Write-Host "== [1/5] Fork check (old fork is stale + has no 'main') =="
$forkOk = $false
gh repo view "$me/litellm" 2>$null | Out-Null
$forkExists = ($LASTEXITCODE -eq 0)
if ($forkExists) {
  gh api "repos/$me/litellm/branches/main" 2>$null | Out-Null
  $forkOk = ($LASTEXITCODE -eq 0)
}
if ($forkExists -and -not $forkOk) {
  $ans = Read-Host "   Your fork has no 'main' (last push 2026-07, no unique work). Delete and re-fork fresh? [Y/n]"
  if ($ans -eq 'n' -or $ans -eq 'N') { Write-Host '   Stopped. Fix the fork default branch in Settings, then re-run.'; exit 1 }
  gh repo delete "$me/litellm" --yes
  $forkExists = $false
}
if (-not $forkExists) { gh repo fork BerriAI/litellm --clone=false; Start-Sleep 5 }

Write-Host '== [2/5] Workspace on E: + fresh shallow clone (~283MB) =='
New-Item -ItemType Directory -Force $WorkRoot | Out-Null
Set-Location $WorkRoot
Invoke-WebRequest $PatchUrl -OutFile 'fix.patch'
Invoke-WebRequest $BodyUrl  -OutFile 'PR-BODY.md'
if (-not (Test-Path '.\repo')) { git clone --depth 1 https://github.com/BerriAI/litellm.git repo }

Write-Host '== [3/5] Branch + apply verified patch =='
Set-Location .\repo
git checkout -b $Branch
git -c "user.name=$me" -c "user.email=$me@users.noreply.github.com" am ..\fix.patch
if ($LASTEXITCODE -ne 0) { Write-Host '  ERROR: patch failed to apply - report this back.'; exit 1 }

Write-Host '== [4/5] Push branch to your fork =='
git push "https://github.com/$me/litellm.git" "${Branch}:${Branch}"
if ($LASTEXITCODE -ne 0) { Write-Host '  ERROR: push failed - check gh auth status and re-run.'; exit 1 }

Write-Host '== [5/5] Open the PR =='
gh pr create --repo BerriAI/litellm --base main --head "${me}:${Branch}" `
  --title "fix(responses): normalize string input to canonical list before provider dispatch" `
  --body-file ..\PR-BODY.md

Write-Host ''
Write-Host 'DONE!' -ForegroundColor Green
Write-Host '   1) When cla-assistant-io comments on the PR -> click and sign the CLA.'
Write-Host '   2) Paste the PR link back to the agent for CI tracking + portfolio prep.'
Write-Host '   3) Later you can free the space:  Remove-Item -Recurse -Force E:\dev\litellm-41963'
