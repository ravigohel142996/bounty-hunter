# ============================================================================
# submit-windows.ps1 — publish the litellm #41962 PR from YOUR GitHub (Windows)
# ----------------------------------------------------------------------------
# - Works entirely on E: (your SD card with 47GB free). C: is NOT touched
#   (except tools you already have installed).
# - Space needed: ~283 MB on E:   |   ~0 MB extra on C:
# - Nothing hidden: read it. It downloads your verified patch + PR text from
#   YOUR bounty-hunter repo, applies, pushes, opens the PR. That's all.
# Prereq: git + gh (script checks and tells you what to do if missing).
# Run:    powershell -ExecutionPolicy Bypass -File E:\submit.ps1
# After:  click "Sign CLA" when the cla-assistant bot comments on the PR.
# ============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$WorkRoot = 'E:\dev\litellm-41962'
$Branch   = 'fix/ollama-completion-thinking-field'
$PatchUrl = 'https://raw.githubusercontent.com/ravigohel142996/bounty-hunter/arena/01a0b9b5-bounty-hunter/artifacts/litellm-41962/0001-fix-ollama-map-JSON-thinking-field-to-reasoning_cont.patch'
$BodyUrl  = 'https://raw.githubusercontent.com/ravigohel142996/bounty-hunter/arena/01a0b9b5-bounty-hunter/artifacts/litellm-41962/PR-BODY.md'

function Have($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

Write-Host "== Checking tools ==" -ForegroundColor Cyan
if (-not (Have 'git')) {
  Write-Host "  git not found. Install once with:"
  Write-Host "    winget install --id Git.Git -e        (needs ~370MB on C:)"
  Write-Host "  or, if C: is too full, extract MinGit portable to E:\dev\tools and add its 'cmd' folder to PATH."
  exit 1
}
if (-not (Have 'gh')) {
  Write-Host "  GitHub CLI not found — installing portable copy onto E: (no C: space used)..."
  New-Item -ItemType Directory -Force 'E:\dev\tools' | Out-Null
  $ver = (Invoke-RestMethod 'https://api.github.com/repos/cli/cli/releases/latest').tag_name.TrimStart('v')
  Invoke-WebRequest "https://github.com/cli/cli/releases/latest/download/gh_${ver}_windows_amd64.zip" -OutFile 'E:\dev\tools\gh.zip'
  Expand-Archive 'E:\dev\tools\gh.zip' 'E:\dev\tools' -Force
  Remove-Item 'E:\dev\tools\gh.zip'
  $env:PATH = "E:\dev\tools\gh_${ver}_windows_amd64\bin;$env:PATH"
}
(git --version); (gh --version) | Select-Object -First 1

Write-Host "== Login (browser opens, your own account — no password in chat) ==" -ForegroundColor Cyan
gh auth status 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { gh auth login }
gh auth setup-git
$me = (gh api user --jq .login).Trim()
Write-Host "   GitHub account: @$me"

Write-Host "== [0/5] Live competition re-check (issue #41962) ==" -ForegroundColor Cyan
$comments = (gh api repos/BerriAI/litellm/issues/41962 --jq .comments).Trim()
$prrefs = (gh api "repos/BerriAI/litellm/issues/41962/timeline?per_page=100" --jq '([.[] | select(.event=="cross-referenced" and .source.issue.pull_request != null)] | length)').Trim()
Write-Host "   comments=$comments   competing-PR-links=$prrefs"
if ($prrefs -ne '0') {
  Read-Host "   WARNING: a competing PR appeared. Ctrl+C to stop and reassess, or Enter to continue anyway"
}

Write-Host "== [1/5] Fork check (old fork is stale + has no 'main') ==" -ForegroundColor Cyan
$forkOk = $false
gh repo view "$me/litellm" 2>$null | Out-Null
$forkExists = ($LASTEXITCODE -eq 0)
if ($forkExists) {
  gh api "repos/$me/litellm/branches/main" 2>$null | Out-Null
  $forkOk = ($LASTEXITCODE -eq 0)
}
if ($forkExists -and -not $forkOk) {
  $ans = Read-Host "   Your fork has no 'main' (last push 2026-07, no unique work). Delete & re-fork fresh? [Y/n]"
  if ($ans -eq 'n' -or $ans -eq 'N') { Write-Host "   Stopped. Fix the fork's default branch in Settings, then re-run."; exit 1 }
  gh repo delete "$me/litellm" --yes
  $forkExists = $false
}
if (-not $forkExists) { gh repo fork BerriAI/litellm --clone=false; Start-Sleep 5 }

Write-Host "== [2/5] Workspace on E: + fresh shallow clone (~283MB of your 47GB) ==" -ForegroundColor Cyan
New-Item -ItemType Directory -Force $WorkRoot | Out-Null
Set-Location $WorkRoot
Invoke-WebRequest $PatchUrl -OutFile 'fix.patch'
Invoke-WebRequest $BodyUrl  -OutFile 'PR-BODY.md'
if (-not (Test-Path '.\repo')) { git clone --depth 1 https://github.com/BerriAI/litellm.git repo }

Write-Host "== [3/5] Branch + apply verified patch ==" -ForegroundColor Cyan
Set-Location .\repo
git checkout -b $Branch
git -c "user.name=$me" -c "user.email=$me@users.noreply.github.com" am ..\fix.patch
if ($LASTEXITCODE -ne 0) { Write-Host "  ERROR: patch failed to apply — report this back."; exit 1 }

Write-Host "== [4/5] Push branch to your fork ==" -ForegroundColor Cyan
git push "https://github.com/$me/litellm.git" "${Branch}:${Branch}"
if ($LASTEXITCODE -ne 0) { Write-Host "  ERROR: push failed — check gh auth status and re-run."; exit 1 }

Write-Host "== [5/5] Open the PR ==" -ForegroundColor Cyan
gh pr create --repo BerriAI/litellm --base main --head "${me}:${Branch}" `
  --title "fix(ollama): map JSON thinking field to reasoning_content in non-streaming completion" `
  --body-file ..\PR-BODY.md

Write-Host ""
Write-Host "✅ Done!" -ForegroundColor Green
Write-Host "   1) When 'cla-assistant-io' comments on the PR → click and sign the CLA."
Write-Host "   2) Paste the PR link back to the agent for CI tracking + portfolio prep."
Write-Host "   3) Later you can free the space:  Remove-Item -Recurse -Force E:\dev\litellm-41962"
