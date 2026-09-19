## TLDR

Problem this solves:

- A `"const"` in a tool/response JSON Schema is silently dropped for Gemini
- The pinned value becomes unconstrained; the call still returns 200

How it solves it:

- A string `const` is forwarded as Vertex's expressible equivalent: single-entry `enum` with `type: string`
- A non-string `const` cannot be expressed by Gemini, so it is dropped with an explicit warning instead of silently

## User Flow

Before: a caller pins a tool argument value (e.g. `"currency": {"const": "USD"}`), but the provider accepts any object for that field

1. They send POST https://litellm-domain/v1/chat/completions with tool parameters containing `"const"`
2. The call returns 200, and nothing signals the constraint was lost
3. The upstream Gemini request carries `{"currency": {"type": "object"}}`, so the model may submit, for example, `"currency": {"x": 1}` and their parser accepts it

After: the pinned value reaches the provider as a constraint Gemini enforces

1. They send the same POST https://litellm-domain/v1/chat/completions with the same tools
2. The upstream Gemini request now carries `{"currency": {"type": "string", "enum": ["USD"]}}`
3. A `const` with a non-string value, which Gemini cannot express, produces a warning in the LiteLLM logs instead of a silent drop

## Relevant issues

Refs #41913 (covers the report's item 1 of 6; the other items are untouched by this PR)

## Affected release

## Linear ticket

## Pre-Submission checklist

- [x] I have added meaningful tests
- [x] The handful of test files covering my change pass locally: `uv run pytest tests/test_litellm/llms/vertex_ai/test_vertex_ai_common_utils.py -v` (93 passed)
- [x] My PR passes all required CI/CD checks (ruff format + both lint lanes + all three budget gates verified locally against the merge-base; CI will re-run the rest)
- [x] My PR's scope is as isolated as possible; it only solves 1 specific problem
- [ ] I have received a Greptile **Confidence Score of at least 4/5** before requesting a maintainer review (runs automatically on open)

## Delays in PR merge?

N/A

## Screenshots / Proof of Fix

Shared setup: the schema-conversion step is a pure mapping of the tool-schema kwargs into the upstream body, invoked identically for every `/v1/chat/completions` call carrying tools; inputs below are exactly the shape from the linked issue's captured wire log.

### Before (origin/main)

#### case 1

1. `python3 -c "from litellm.llms.vertex_ai.common_utils import _build_vertex_schema; print(_build_vertex_schema({'type':'object','properties':{'amount':{'type':'number'},'currency':{'const':'USD'}},'required':['currency','amount']}))"`
2. Observed: `{'type': 'object', 'properties': {'amount': {'type': 'number'}, 'currency': {'type': 'object'}}, 'required': ['currency', 'amount']}` — the pin is gone, it is the `{'type': 'object'}` from the reporter's `--detailed_debug` capture

#### case 2

1. `python3 -c "from litellm.llms.vertex_ai.common_utils import _build_vertex_schema; print(_build_vertex_schema({'type':'object','properties':{'value':{'type':'string','const':'fixed'}}}))"`
2. Observed: `{'type': 'object', 'properties': {'value': {'type': 'string'}}}` — `const` swallowed silently

### After (<tip sha>)

#### case 1

1. Same command as Before
2. Observed: `{'type': 'object', 'properties': {'amount': {'type': 'number'}, 'currency': {'type': 'string', 'enum': ['USD']}}, 'required': ['currency', 'amount']}` — Gemini now enforces the pinned value

#### case 2

1. Same command as Before
2. Observed: `{'type': 'object', 'properties': {'value': {'type': 'string', 'enum': ['fixed']}}}`

## Type

🐛 Bug Fix

## Caveats (if any)

### Medium

- A non-string `const` (e.g. number/bool) still cannot be expressed by Gemini's string-only enums; it is now dropped with an explicit warning rather than silently. Preserving those constraints is follow-up work

## Final Attestation

- [x] The tests check the right things, including the edge cases, and regressions in the respective real-world customer use-cases are not possible after this PR
