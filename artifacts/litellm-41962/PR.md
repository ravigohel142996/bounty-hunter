# PR handoff — BerriAI/litellm #41962 (Stage-3 output, NOT yet submitted)

**Branch:** `fix/ollama-completion-thinking-field`
**Commit message:** `fix(ollama): map JSON thinking field to reasoning_content in non-streaming completion`
**Upstream base at build time:** `BerriAI/litellm@12593788a28f` (main, 2026-09-19 13:08 UTC)
**Patch file:** `artifacts/litellm-41962/0001-fix-ollama-map-JSON-thinking-field-to-reasoning_cont.patch`

---

## PR Title (paste as-is)

```
fix(ollama): map JSON thinking field to reasoning_content in non-streaming completion
```

## PR Body (paste as-is)

```markdown
## Problem
Closes #41962

On non-streaming Ollama **completion** (`/api/generate`) responses, Ollama returns the
model's reasoning in a structured JSON `thinking` field (e.g. gpt-oss / qwen3 with
`think=true`). The `ollama/` completion transport only parses inline `<think>` tags from
the `response` text, so the structured reasoning was dropped entirely: `reasoning_content`
came back `None`, and when the model puts its whole turn into `thinking`, `content` came
back empty **while tokens are still billed**.

## Root cause
`litellm/llms/ollama/completion/transformation.py` — `OllamaConfig.transform_response()`
non-streaming branch only called `_parse_content_for_reasoning(response_text)` and never
read `response_json["thinking"]`. The sibling chat transport
(`litellm/llms/ollama/chat/transformation.py`) already maps `thinking` → `reasoning_content`.

## Fix
Mirror the chat transport in the non-streaming completion branch:

- if `response_json["thinking"]` is present and non-empty → map it to
  `message.reasoning_content`, use `response` as `content` as-is
- otherwise → existing behavior (`_parse_content_for_reasoning` on `response`) is unchanged

No changes to the streaming path (already handled by the chunk parser) and no changes to
the JSON-mode branch. Diff is +9/−1 lines in one file.

## Tests
Added 2 mocked regression tests in `tests/test_litellm/llms/ollama/test_ollama_completion_transformation.py`
(following the existing `TestOllamaConfig` style):

- `test_transform_response_with_json_thinking_field` — `thinking` + non-empty `response`
  → both `reasoning_content` and `content` populated correctly
- `test_transform_response_with_json_thinking_field_only` — whole turn inside `thinking`
  (empty `response`) → reasoning preserved, `content == ""`

Verification on `main @ 12593788a28f`:

- Both new tests **fail on unpatched code** with the exact issue symptom
  (`reasoning_content is None`) → they genuinely reproduce the bug
- `pytest tests/test_litellm/llms/ollama/test_ollama_completion_transformation.py -q` → **16/16 passed**
- `pytest tests/test_litellm/llms/ollama/test_ollama_chat_transformation.py -q` → 27/27 passed (no collateral)
- `ruff format --check` (ruff==0.15.3, line-length 120) → clean for changed lines
- `ruff check --config ruff.toml` (source) / `ruff check --config ruff-tests.toml` (tests) → clean
```

---

## ⚠️ Manual steps required before the PR exists (Stage 4 — needs your OK)

> Your fork has **no `main` branch** — its default branch is `litellm_internal_staging`,
> last synced **2026-07-03**. Fix this first or the PR will open against a stale base.

```bash
# 1. Fix & sync your fork (easiest: github.com/ravigohel142996/litellm → Settings → renamed branch,
#    or delete the fork and re-fork; then "Sync fork". CLI path:)
gh repo fork BerriAI/litellm --clone=false          # if you re-fork
# 2. Apply the verified commit onto fresh upstream:
git clone https://github.com/ravigohel142996/litellm && cd litellm
git remote add upstream https://github.com/BerriAI/litellm && git fetch upstream
git checkout -b fix/ollama-completion-thinking-field upstream/main
git am < 0001-fix-ollama-map-JSON-thinking-field-to-reasoning_cont.patch   # from this artifacts dir
git push -u origin fix/ollama-completion-thinking-field
# 3. Sign the BerriAI CLA when the cla-assistant bot comments (hard requirement in CONTRIBUTING.md)
# 4. Open the PR with the title/body above — base: BerriAI/litellm main
```

**Immediately before opening the PR, re-verify nothing changed (competition check):**
```bash
gh api repos/BerriAI/litellm/issues/41962 --jq '{state, comments, assignees:[.assignees[].login]}'
gh api "repos/BerriAI/litellm/issues/41962/timeline?per_page=100" \
  --jq '[.[] | select(.event=="cross-referenced" and .source.issue.pull_request != null)] | length'
# If a competing PR appeared → rebase still fine, but assess before submitting.
```

## Checklist status
- [x] Minimal diff (1 source file, +9/−1; 1 test file, +94)
- [x] ≥1 mocked test added (hard requirement) — 2 added, fail-without-fix proven
- [x] ruff format + both ruff check lanes pass on changed lines (`ruff==0.15.3`)
- [x] Conventional Commits message
- [x] No real API calls in tests
- [ ] CLA signed — **you** must do this at PR time (external agreement; not done by the agent)
- [ ] PR opened — awaiting your explicit approval (Stage 4)
