---
name: link-headers
description: Add HTTP `Link` response headers to a homepage for agent discovery per RFC 8288 and RFC 9727 §3, using registered relations like `api-catalog`, `service-desc`, `service-doc`, and `describedby`. Use when exposing machine-readable resources to crawlers/agents, adding Link headers via origin server, Cloudflare Transform Rules, or Workers, or validating against isitagentready.com's `linkHeaders` check.
metadata:
  tags: link-headers, rfc8288, rfc9727, discovery, agents, cloudflare, http-headers
source: https://isitagentready.com/.well-known/agent-skills/link-headers/SKILL.md
---

# Implement Link Response Headers

Add Link response headers to your homepage for agent discovery per
[RFC 8288](https://www.rfc-editor.org/rfc/rfc8288) and
[RFC 9727 Section 3](https://www.rfc-editor.org/rfc/rfc9727#section-3).

## Requirements

- Return `Link` headers on your homepage response pointing to machine-readable resources
- Use registered relation types: `api-catalog`, `service-desc`, `service-doc`, `describedby`
- Example: `Link: </.well-known/api-catalog>; rel="api-catalog"`
- Multiple Link headers or comma-separated values are both valid

## Cloudflare

Use [Transform Rules](https://developers.cloudflare.com/rules/transform/) or
[Workers](https://developers.cloudflare.com/workers/) to add Link headers
without modifying your origin server.

## Validate

```
POST https://isitagentready.com/api/scan
Content-Type: application/json

{"url": "https://YOUR-SITE.com"}
```

Check that `checks.discoverability.linkHeaders.status` is `"pass"`.
