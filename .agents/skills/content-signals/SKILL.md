---
name: content-signals
description: Declare AI content usage preferences (ai-train, search, ai-input) via `Content-Signal` directives in robots.txt per the IETF aipref draft and contentsignals.org spec. Use when configuring how crawlers may use site content for AI training or search, editing robots.txt for AI bot governance, enabling Cloudflare AI Crawl Control content signals, or validating against isitagentready.com's `contentSignals` check.
metadata:
  tags: robots-txt, ai-crawlers, content-signals, aipref, cloudflare, governance
source: https://isitagentready.com/.well-known/agent-skills/content-signals/SKILL.md
---

# Implement Content Signals

Declare AI content usage preferences in your robots.txt using
[Content Signals](https://contentsignals.org/)
([IETF draft](https://datatracker.ietf.org/doc/draft-romm-aipref-contentsignals/)).

## Requirements

- Add `Content-Signal` directives to your robots.txt under the relevant `User-agent` block
- Declare preferences for `ai-train`, `search`, and `ai-input`
- Example: `Content-Signal: ai-train=no, search=yes, ai-input=no`

## Cloudflare

[AI Crawl Control](https://developers.cloudflare.com/ai-crawl-control/)
supports Content Signals configuration from the dashboard.

## Validate

```
POST https://isitagentready.com/api/scan
Content-Type: application/json

{"url": "https://YOUR-SITE.com"}
```

Check that `checks.botAccessControl.contentSignals.status` is `"pass"`.
