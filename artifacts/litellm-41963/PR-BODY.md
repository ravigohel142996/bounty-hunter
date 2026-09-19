## Problem
Closes #41963

OpenAI's Responses API documents `input` as accepting either a string or an array, so SDKs
and clients legitimately send the string form. Providers whose transform only handles the
array form (e.g. the reporter's `chatgpt/` deployment) turn that spec-compliant request
into a 400 that looks like a client bug:

```
{"error":{"message":"litellm.BadRequestError: ChatgptException - {\"detail\":\"Input must be a list\"}" ... }}
```

## Root cause
In `litellm/responses/main.py`, `responses()` forwards `input: str | ResponseInputParam`
to provider dispatch unchanged. Nothing normalizes the string shorthand before the
per-provider transforms run.

## Fix
Add `_normalize_responses_api_string_input()` and call it once, centrally, in
`responses()` immediately before dispatch — so **every** downstream lane sees the
canonical shape: MCP gateway, emulated file search, the chat-completions bridge, and
native providers (`base_llm_http_handler.response_api_handler`). List input passes
through untouched. +25 lines in one source file; no provider transforms modified.

`input = "Reply with exactly ROUTE_OK."` becomes `[{"role": "user", "content": "Reply with exactly ROUTE_OK."}]` — the exact canonical form requested in the issue.

## Tests
New `tests/test_litellm/responses/test_string_input_normalization.py` (6 mocked tests):

- **helper**: string → canonical list · list → pass-through · empty string · non-ASCII preserved
- **dispatch-level**: patched `base_llm_http_handler` proves `responses()` hands the native
  provider the normalized list for string input, and content-intact list for list input

Verification on `main @ 5d28684`:

- **Behavior-level toggle proof** — unpatched: handler receives raw string
  `'Reply with exactly ROUTE_OK.'` (the bug) · patched: handler receives
  `[{'role': 'user', 'content': 'Reply with exactly ROUTE_OK.'}]`
- `pytest tests/test_litellm/responses/test_string_input_normalization.py -q` → **6/6 passed**
- `ruff format --check` (ruff==0.15.3) + `ruff check` (`ruff.toml` / `ruff-tests.toml`) → clean
- Collateral: `test_dispatch.py` (1 failed/9 passed) and `test_responses_api_bridge_flag.py`
  (1 error) show the *identical* results on unpatched `main` — pre-existing environment
  noise, not regressions from this change
