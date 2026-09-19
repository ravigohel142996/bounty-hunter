## Problem
Closes #41962

On non-streaming Ollama **completion** (`/api/generate`) responses, Ollama returns the model's
reasoning in a structured JSON `thinking` field (e.g. gpt-oss / qwen3 with `think=true`).
The `ollama/` completion transport only parses inline `<think>` tags from the `response`
text, so the structured reasoning was dropped entirely: `reasoning_content` came back
`None`, and when the model puts its whole turn into `thinking`, `content` came back empty
**while tokens are still billed**.

## Root cause
`litellm/llms/ollama/completion/transformation.py` — `OllamaConfig.transform_response()`
non-streaming branch only called `_parse_content_for_reasoning(response_text)` and never
read `response_json["thinking"]`. The sibling chat transport
(`litellm/llms/ollama/chat/transformation.py`) already maps `thinking` → `reasoning_content`.

## Fix
Mirror the chat transport in the non-streaming completion branch:

- if `response_json["thinking"]` is present and non-empty → map it to `message.reasoning_content`, use `response` as `content` as-is
- otherwise → existing behavior (`_parse_content_for_reasoning` on `response`) is unchanged

No changes to the streaming path (already handled by the chunk parser) and no changes to
the JSON-mode branch. Diff is +9/−1 lines in one source file.

## Tests
Added 2 mocked regression tests in `tests/test_litellm/llms/ollama/test_ollama_completion_transformation.py`:

- `test_transform_response_with_json_thinking_field` — `thinking` + non-empty `response` → both fields populated
- `test_transform_response_with_json_thinking_field_only` — whole turn inside `thinking` (empty `response`) → reasoning preserved, `content == ""`

Verification on `main @ 12593788a28f`:

- Both new tests **fail on unpatched code** with the exact issue symptom (`reasoning_content is None`)
- `pytest tests/test_litellm/llms/ollama/test_ollama_completion_transformation.py -q` → **16/16 passed**
- `pytest tests/test_litellm/llms/ollama/test_ollama_chat_transformation.py -q` → 27/27 passed (no collateral)
- `ruff format --check` (ruff==0.15.3, line-length 120) + `ruff check` (ruff.toml / ruff-tests.toml lanes) → clean
