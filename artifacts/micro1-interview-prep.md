# micro1 AI Interview Prep — Open Source Contributor (GitHub) role
Interview: up to 34 min, conversational AI ("Zara"), mic+camera ON, SCREEN SHARE likely.
Deadline: Sep 24, 2026 06:34 AM — DO IT SEP 22 or SEP 23 morning, not last-minute.
Focus areas (their words): Front-End Experience | Back-End Expertise | End-to-End Full-Stack Integration | AI-Assisted Software Development | Full-Stack Architecture Ownership

## RULES
1. Speak from understanding, in YOUR words — never read this doc on screen (AI interviewers flag monotone reading + second-screen glances; this doc is for memorizing the skeleton, not reciting).
2. Every claim must be verifiable on your public GitHub. If you don't know something, say "I haven't worked with X deeply; here's how I'd approach learning it."
3. Structure every answer as: Context → what YOU did (specific files/decisions) → result (numbers).

## ANCHOR STORY (memorize — 90 seconds, spoken)
"I contribute to litellm — one of the biggest LLM-gateway proxies, Python. Bug: when users passed JSON Schema `const` in tool/response schemas for Google's Vertex/Gemini, litellm's translation pipeline silently DROPPED it, so the model's output was no longer pinned to that value. I traced it to a whitelist filter in the Vertex common-utils layer that only kept keys from Gemini's Schema TypedDict — `const` isn't one of them. My fix translated string consts into the Gemini-native equivalent: `type: string` plus a one-element `enum` — because Gemini only supports enums on strings. Non-string consts can't be expressed in Gemini at all, so I surface a warning naming the dropped value instead of failing silently. Edge cases I handled: if the field already had an `enum` or an explicit `type`, I don't overwrite them. Tests: added four regression tests to the mapped test file; every other vertex test passed unchanged; my PR passed ruff, strict-type gates, the repo's quality budgets. First push actually failed two CI policy gates — one was a whitelist of recursive functions (my walker was recursive), the other was bare-list-literal discipline — so I rewrote it as an iterative stack-based walk with the repo's markers. That taught me to read a repo's contribution rules BEFORE writing code. Second PR in the same repo normalized the Responses API's string input across providers — 84 CI checks green."

### If they probe deeper on the litellm PRs (likely!)
- Q: Why enum instead of supporting const? → "Gemini's Schema object has no const field; enum with one element is its only native way to pin a value — and only for strings."
- Q: Why warning instead of raising? → "Provider translation is best-effort, matching litellm's design — you never hard-fail a user request over an inexpressible constraint; you log loudly instead."
- Q: What did the failing CI gates teach you? → "The repo ratchets quality via scripts: a recursion whitelist, mutable-collection markers (LIT002), test-quality budgets. New code must fit those — read CONTRIBUTING/AGENTS docs first."
- Q: How did you test? → "Unit tests through the public entry point `_build_vertex_schema` — verifying the OUTPUT schema — plus edge cases: explicit type + const, existing enum, non-string const via caplog."
- Q: Walk me through the diff on screen → Be ready to open: PR #42259 "Files changed" tab and narrate: helper before `_build_vertex_schema`, call site after `_convert_schema_types`, tests below.

## THE 5 FOCUS AREAS — likely questions + your answer skeletons

### A. Front-End Experience (React/JS/TS — your working level, NOT your deepest lane)
- "Walk me through a front-end you built." → Use YOUR real project (Streamlit counts as UI too, but name a React one if you have it): what it does, component structure, state handling, one real bug you fixed.
- "How do you debug a UI issue in an unfamiliar codebase?" → Reproduce → DevTools (network/console/component tree) → find the state flow → minimal repro → fix behind a test/story.
- Rapid-fire to be ready for: props vs state, useEffect cleanup, keys in lists, controlled inputs, fetch/async in components, CORS basics.
- If they push beyond your depth: "My front-end is working-level; Python/back-end is where I'm deepest — and I navigate unfamiliar front-ends methodically, which is what this role's repo-exploration is about."

### B. Back-End Expertise (YOUR home turf — go deep)
- "Describe a back-end bug you fixed end-to-end" → the litellm story.
- "How does a request flow through an LLM gateway?" → route handler → auth/rate-limit → provider dispatch (litellm router) → per-provider translation layer (THE layer I fixed) → upstream API → response normalization → logging/cost tracking.
- Rapid-fire: HTTP methods/status (400/401/403/404/409/422/429/500), REST vs streaming (SSE — litellm streams!), async Python (asyncio event loop, await), FastAPI dependency injection, idempotency, pagination, webhooks.
- Testing: "What makes a good regression test?" → "Fails before the fix, passes after, uses the public interface, names the bug."

### C. End-to-End Full-Stack Integration
- "Trace data across a system" → litellm #41984 story: a plain string sent to `/v1/responses` hit provider dispatch un-normalized → different providers choked differently; fix = normalize once at the boundary before dispatch, like the rest of the gateway does. Lesson: boundaries are where integrations break.
- Methodology: start at the entry point, follow types through transformation layers, add tests at the boundary.
- Rapid-fire: serialization (JSON), schema validation, API versioning, error propagation, timeouts/retries.

### D. AI-Assisted Software Development (THIS ROLE'S core — be HONEST and specific)
- Expected: they want to know HOW you work with AI tools (the job = reviewing AI-generated patches!).
- Your honest, strong answer: "I use AI assistants as pair programmers daily. My rules: (1) I understand every line before it ships — AI drafts, I own; (2) tests and CI are the ground truth, not the AI's confidence; (3) I verify claims about external APIs against source. My litellm PRs were built this way — AI-assisted exploration, human verification, 84 green checks."
- "How do you review an AI-generated patch?" → checklist: does it actually fix the stated issue (reproduce first!), edge cases (nulls/empty/unicode), security (injection, secrets), does it fit the repo's architecture and CONTRIBUTING rules, does it add tests, does it touch unrelated code (red flag).
- If asked "do you pass off AI output as your own?" → "No. Assisted work is disclosed where required, and everything I submit is verified and understood — my GitHub diffs are small, reviewed, and tested."

### E. Full-Stack Architecture Ownership
- "Tell me about a system you owned end-to-end" → use YOUR project: what it does, why you chose the stack, data model, deployment (Docker?), one scaling/design decision and its tradeoff, one thing you'd rebuild differently.
- If your project is small: own it — "It's a small project, but I made every layer decision consciously: thin FastAPI API, single Postgres table, Streamlit front — and here's the decision I'd revisit."
- Rapid-fire: monolith vs services, when NOT to microservice, DB indexing basics, environment configs/secrets, Docker basics (you have Docker in your stack).

## RAPID-FIRE BANK (warm up 1 hour before)
Git: rebase vs merge, git bisect, reading diffs, force-push --force-with-lease.
Python: dict/list comprehension, generators, GIL (one line), typing basics, dataclasses/pydantic.
JSON Schema (your PR domain!): type, properties, required, enum, const, anyOf, $ref.
LLM APIs: messages vs responses API, function/tool calling, response_format/structured outputs, why providers differ (litellm exists to abstract this!).
Security: never log secrets, input validation at boundaries, injection classes.

## SCREEN-SHARE SETUP (do BEFORE starting)
Open in tabs, top-left order:
1. github.com/ravigohel142996 (profile)
2. PR #42259 → Files changed
3. PR #41984 → Files changed
4. litellm/llms/vertex_ai/common_utils.py on main (the file you changed)
5. Your best own project repo (README visible)
Practice out loud: "This is my PR fixing schema translation... here's the helper, here's where it's called, here are the tests."

## LOGISTICS CHECKLIST
- Quiet room, phone outside, Do-Not-Disturb ON, laptop PLUGGED IN, mic+cam tested, stable internet (mobile hotspot ready as backup).
- Water nearby, 45 uninterrupted minutes blocked.
- One A4 note allowed OFF to the side with just keywords: LITELLM / CONST→ENUM / WARN NOT FAIL / 84 GREEN / V1→V2 CI LESSON. Glance only.
- Speak clearly, moderate speed; pause 1s before answering; if a question glitches, ask it to repeat — that's normal with Zara.
- Don't panic if a question is hard — depth answers > coverage answers.
