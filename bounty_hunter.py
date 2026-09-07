#!/usr/bin/env python3
"""
🤖 BOUNTY HUNTER BOT — for Ravi (ravigohel142996)
Auto-finds REAL paid Python/AI bounties on GitHub and kills scam ones.
Run:  python3 bounty_hunter.py
(Optional) set GITHUB_TOKEN env var for higher API limits.
"""

import json
import os
import re
import sys
import urllib.request
import urllib.parse
from datetime import datetime, timezone

TOKEN = os.environ.get("GITHUB_TOKEN", "")
HEADERS = {
    "Accept": "application/vnd.github+json",
    "User-Agent": "bounty-hunter-bot",
}
if TOKEN:
    HEADERS["Authorization"] = f"Bearer {TOKEN}"

# ---------- SCAM FILTER ----------
SCAM_TITLE_PATTERNS = [
    r"\bstar\b", r"\bstarred\b", r"\bfollow\b", r"\bsubscribe\b",
    r"\breview\b.*(?:toolpilot|product)", r"\bsocial media\b", r"\bpromote\b",
    r"\bshare\b.*post", r"\byoutube video\b", r"\bbadge\b.*readme",
    r"\bwhy did you choose\b", r"\bwrite a comparison\b", r"\bleave an?\b.*review",
    r"\bmicro.?bounty\b", r"\btip jar\b", r"\bmemes?\b", r"\bquiz\b",
]
SCAM_TOKEN_WORDS = ["RTC", "tokens)", "crypto reward", "pool:"]
GOOD_REPO_MIN_STARS = 80          # real bounty projects have traction
MAX_REPO_AGE_DAYS = 730           # scam farms are brand new
KNOWN_SCAM_REPOS = {
    "scottcjn/rustchain-bounties", "zhangjiayang6835-cyber/bounty-plaza",
    "ikalus1988/misakanet", "aadarwal/swarmstatus-bounties",
}

# Projects that historically pay (whitelist boost)
TRUSTED_ORGS = {
    "onyx-dot-app", "BerriAI", "comfyanonymous", "comfy-org", "pydantic",
    "deepset-ai", "chroma-core", "langgenius", "openedx", "oppia",
    "expensify", "rudderlabs", "triggerdotdev", "tscircuit",
}

QUERIES = [
    'label:"💎 Bounty" language:python state:open',
    'label:"💰 Bounty" language:python state:open',
    'label:"💎 bounty" language:python state:open',
    'label:bounty algora language:python state:open',
    'label:bounty language:python state:open sort:updated',
]


def gh_api(url):
    req = urllib.request.Request(url, headers=HEADERS)
    try:
        with urllib.request.urlopen(req, timeout=25) as r:
            return json.load(r), None
    except urllib.error.HTTPError as e:
        if e.code == 403 and "rate limit" in e.headers.get("x-ratelimit-remaining", ""):
            return None, "RATE_LIMITED"
        return None, f"HTTP {e.code}"
    except Exception as e:
        return None, str(e)


def repo_info(full_name, cache):
    if full_name in cache:
        return cache[full_name]
    d, err = gh_api(f"https://api.github.com/repos/{full_name}")
    info = None
    if d and not err:
        created = d.get("created_at", "2100-01-01T00:00:00Z")[:10]
        from datetime import date
        try:
            age_days = (date.today() - date.fromisoformat(created)).days
        except ValueError:
            age_days = 99999
        info = {
            "stars": d.get("stargazers_count", 0),
            "age_days": age_days,
            "pushed": (d.get("pushed_at") or "")[:10],
            "archived": d.get("archived", False),
        }
    cache[full_name] = info
    return info


def is_scam(title, repo_full, body, stars, age_days):
    t = title.lower()
    if repo_full.lower() in KNOWN_SCAM_REPOS:
        return "known scam farm"
    for p in SCAM_TITLE_PATTERNS:
        if re.search(p, t):
            return f"scam pattern: {p}"
    for w in SCAM_TOKEN_WORDS:
        if w.lower() in t or (body and w.lower() in body[:400].lower()):
            return "pays in unknown tokens"
    if stars is not None and stars < GOOD_REPO_MIN_STARS:
        return f"low stars ({stars})"
    if age_days is not None and age_days < 90:
        return f"repo too new ({age_days}d)"
    return None


def usd_amount(title, body):
    """Try to find a USD reward in title/body."""
    text = (title + " " + (body or ""))[:1200]
    m = re.findall(r"\$\s?(\d{2,5}(?:,\d{3})?)", text)
    amounts = [int(a.replace(",", "")) for a in m]
    return max(amounts) if amounts else None


def score(item, stars, amount):
    s = 0
    repo_full = item["repository_url"].split("repos/")[-1]
    org = repo_full.split("/")[0]
    if org in TRUSTED_ORGS:
        s += 50
    if stars:
        s += min(stars // 100, 30)
    if amount:
        s += min(amount // 10, 30)
    if item.get("comments", 0) < 5:
        s += 10  # less competition
    return s


def main():
    print("🤖 BOUNTY HUNTER scanning GitHub for Python/AI bounties...\n")
    seen, found, cache = set(), [], {}
    errors = 0

    for q in QUERIES:
        url = "https://api.github.com/search/issues?per_page=25&sort=updated&q=" + urllib.parse.quote(q)
        d, err = gh_api(url)
        if err:
            errors += 1
            print(f"   (query skipped: {err})")
            if err == "RATE_LIMITED":
                print("   ⚠️ GitHub rate limit — set GITHUB_TOKEN env var for 10x more searches")
                break
            continue
        for it in d.get("items", []):
            html = it["html_url"]
            if html in seen or "pull_request" in it:
                continue
            seen.add(html)
            repo_full = it["repository_url"].split("repos/")[-1]
            info = repo_info(repo_full, cache)
            stars = info["stars"] if info else None
            age = info["age_days"] if info else None
            if info and info["archived"]:
                continue
            scam = is_scam(it["title"], repo_full, it.get("body", ""), stars, age)
            if scam:
                continue
            amount = usd_amount(it["title"], it.get("body", ""))
            found.append({
                "title": it["title"][:100],
                "repo": repo_full,
                "stars": stars or "?",
                "url": html,
                "amount": amount,
                "comments": it.get("comments", 0),
                "labels": ", ".join(l["name"] for l in it.get("labels", []))[:60],
                "updated": it["updated_at"][:10],
                "score": score(it, stars or 0, amount),
            })

    found.sort(key=lambda x: -x["score"])

    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    lines = [
        "# 🤖 Auto Bounty Report — Python / AI",
        f"_Generated: {now}_\n",
        f"**Real bounties found: {len(found)}** (scams & token-farms auto-filtered 🗑️)\n",
    ]
    if not found:
        lines.append("No clean USD bounties right now — check again tomorrow, or browse:\n"
                     "- https://algora.io (login → bounties)\n"
                     "- https://opencollective.com/bounties\n")
    for i, b in enumerate(found, 1):
        usd = f" **~${b['amount']}**" if b["amount"] else ""
        lines.append(f"## {i}. {b['title']}{usd}")
        lines.append(f"- 📦 `{b['repo']}` · ⭐ {b['stars']} · 💬 {b['comments']} comments · 🏷️ {b['labels']}")
        lines.append(f"- 🔗 {b['url']}")
        lines.append(f"- 📅 updated {b['updated']} · match-score {b['score']}\n")

    report = "\n".join(lines)
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "BOUNTIES.md")
    with open(out, "w") as f:
        f.write(report)
    print(report)
    print(f"\n✅ Saved → {out}")
    if errors:
        sys.exit(0)


if __name__ == "__main__":
    main()
