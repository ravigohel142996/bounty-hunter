#!/usr/bin/env bash
# ============================================================================
# submit.sh — publish the litellm #41962 PR from YOUR OWN GitHub login
# ----------------------------------------------------------------------------
# What it does (safe to read first — nothing hidden):
#   0. Re-checks the live issue for last-minute competing PRs
#   1. Makes sure your fork of BerriAI/litellm exists and has a `main` branch
#   2. Clones your fork, fetches fresh upstream main
#   3. Applies the verified patch (branch: fix/ollama-completion-thinking-field)
#   4. Pushes the branch to YOUR fork
#   5. Opens the PR to BerriAI/litellm with the prepared title + body
#
# Prereq: GitHub CLI logged in as YOU  ->  run `gh auth login` first, pick
#         github.com / HTTPS / browser flow. (Never run this with a token that
#         someone sent you in chat — only your own `gh auth login`.)
#
# Usage:  bash submit.sh
# After the PR opens: sign the CLA when "cla-assistant-io" comments (1 click).
# ============================================================================
set -euo pipefail

BRANCH="fix/ollama-completion-thinking-field"
UPSTREAM_URL="https://github.com/BerriAI/litellm.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${1:-$HOME/litellm-41962-submit}"

echo "== [0/5] Live competition re-check (issue #41962) =="
COMMENTS="$(gh api repos/BerriAI/litellm/issues/41962 --jq .comments)"
PRREFS="$(gh api 'repos/BerriAI/litellm/issues/41962/timeline?per_page=100' --jq '[.[] | select(.event=="cross-referenced" and .source.issue.pull_request != null)] | length')"
echo "   comments=$COMMENTS  competing-PR-links=$PRREFS"
if [ "$PRREFS" != "0" ]; then
  echo "⚠️  A competing PR appeared since this patch was verified."
  printf "   Press Ctrl-C to stop and reassess, or Enter to continue anyway: "
  read -r _
fi

ME="$(gh api user --jq .login)"
echo "   Using GitHub account: @$ME"

echo "== [1/5] Checking your fork =="
if ! gh repo view "$ME/litellm" >/dev/null 2>&1; then
  echo "   No fork yet — forking BerriAI/litellm…"
  gh repo fork BerriAI/litellm --clone=false
  sleep 5   # let GitHub finish the fork
fi
if ! gh api "repos/$ME/litellm/branches/main" >/dev/null 2>&1; then
  echo "⚠️  Your fork's default branch is 'litellm_internal_staging' (no 'main')."
  echo "   Cleanest fix: delete & re-fork (your old fork has no unique work to keep:"
  echo "   its last push was 2026-07-03 and it's all upstream code)."
  printf "   Delete $ME/litellm and re-fork fresh? [y/N] "
  read -r ans
  if [ "${ans:-N}" = "y" ] || [ "${ans:-N}" = "Y" ]; then
    gh repo delete "$ME/litellm" --yes
    gh repo fork BerriAI/litellm --clone=false
    sleep 5
  else
    echo "   Aborted. Alternatively fix the default branch in the fork's Settings page, then re-run."
    exit 1
  fi
fi

echo "== [2/5] Cloning your fork + fetching fresh upstream main =="
rm -rf "$WORK"
gh repo clone "$ME/litellm" "$WORK" -- --depth 50
cd "$WORK"
git remote add upstream "$UPSTREAM_URL" 2>/dev/null || true
git fetch --depth 1 upstream main

echo "== [3/5] Applying the verified patch =="
git checkout -b "$BRANCH" FETCH_HEAD
git am "$SCRIPT_DIR/0001-fix-ollama-map-JSON-thinking-field-to-reasoning_cont.patch"

echo "== [4/5] Pushing branch to your fork =="
git push -u origin "$BRANCH"

echo "== [5/5] Opening the PR =="
gh pr create --repo BerriAI/litellm --base main --head "$ME:$BRANCH" \
  --title "fix(ollama): map JSON thinking field to reasoning_content in non-streaming completion" \
  --body-file "$SCRIPT_DIR/PR-BODY.md"

echo ""
echo "✅ Done. Last step: when the 'cla-assistant-io' bot comments on the PR,"
echo "   click and sign the CLA (required by litellm's CONTRIBUTING.md)."
