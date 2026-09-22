# Income-first mission plan (2026-09-22) — verified lanes

Mission pivot: prioritize first REAL payment; GitHub profile as secondary. All lanes below verified 2026-09-22 via live search (see sources in session memory).

## Lane A — Weekly-pay AI gig platforms (PRIMARY, fastest legit cash)
| Platform | India | Pay | Payout | Speed to 1st $ | Notes |
|---|---|---|---|---|---|
| micro1.com | YES (explicit) | $22–40/hr typical, up to $200 specialists | USD via Deel, ~2x/month | ~2–4 wks | AI interview 1h; onboarding 1–3d; never charges fees; set availability 30–40h, rate band $25–40 |
| mercor.com | YES | coding $35–60/hr; avg cited $85/hr | Stripe weekly (Wed) | 1–4 wks to match | selective; phone verification; monitoring app required during work |
| alignerr.com | YES | varies | Stripe/PayPal | 1–3 wks | real but inconsistent payments/projects — treat as bonus lane only |

Scam rule: official domains ONLY; any "pay to apply" or crypto-request = impersonator.

## Lane C — Technical writing (high $/piece, skill-fit)
- Draft.dev: $315–578/article — apply via draft.dev write-for-us, book discovery call.
- Airbyte writers program: $300–500 (+$200 bonus) — data engineering tutorials, Typeform app.
- Master list: github.com/malgamves/CommunityWriterPrograms (verified-active March 2026 entries: Corellium $500–1500, Twilio $500–650, Honeybadger $500, Semaphore ≤$500, Vultr ≤$800, Civo $200–500, SitePoint $250).
- DEAD/paused: LogRocket, DigitalOcean, Earthly.
- Best sample topic (authentic): "Debugging litellm's Vertex AI schema translation — JSON Schema const silently dropped" (real work this week, PRs #42259/#41984 as receipts).

## Lane D — Funded OSS bounties (secondary, filtered)
- Algora: legit, Stripe Express payout (KYC at payout), 1–3 biz days post-merge, BUT agent-saturated (~15% merge rate; fresh bounties get 8–158 attempts). Strategy: only issues <3 comments, posted >48h, no linked PR, exact skill-fit.
- Opire (app.opire.dev): newer, ~5% fee, filter by language — check periodically.
- REJECTED: BasedHardware/omi (542 "bounty" issues ALL proposed-not-funded); BountyHub unverified; Polar pledges dead; algora.io/bounties board + /api/orgs/* 404 from sandbox — discovery via gh search instead:
  `gh api "search/issues?q=is:issue+is:open+bounty+in:title+created:>YYYY-MM-DD" --jq ...` then verify funded evidence in comments/body (bot badge with $ amount + org payout history) before recommending.

## Lane B — Freelance (slow-burn, start profile now)
Upwork + Fiverr wedge: "$10–50 fixed" micro-gigs — Streamlit/FastAPI AI demo dashboards, RAG chatbot starter, n8n/LangChain wiring. First win realistic 2–4 wks; needs zero review bottleneck once started.

## Lane E — In-flight litellm PRs (profile value only — VERIFIED $0 attached)
- #42259 (fix/gemini-schema-const): v2 patch b5fbc648 ready; user runs corrected PowerShell block (branch name FIXED: fix/gemini-schema-const).
- #41984: 84✓/0✗ awaiting human review.
- #41782: no $ markers found on any of the three issues (41913/41963/41782) — pure contribution.

## Honest timeline
48h money = not real legitimately. Realistic: Lane A first payment 2–4 wks; Lane C first paid article 3–6 wks; Lane D bonus merges anytime; Lane B 2–4 wks. Run ALL lanes in parallel = no single-maintainer waiting again.
