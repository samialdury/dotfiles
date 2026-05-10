---
name: api-catalog
description: Publish a discoverable API catalog at `/.well-known/api-catalog` per RFC 9727 using `application/linkset+json` with `service-desc`, `service-doc`, and `status` link relations. Use when exposing OpenAPI specs and docs for agent discovery, wiring up well-known URIs, building automated API discovery endpoints, or validating against isitagentready.com's `apiCatalog` check.
metadata:
  tags: api-catalog, well-known, rfc9727, linkset, openapi, discovery, agents
source: https://isitagentready.com/.well-known/agent-skills/api-catalog/SKILL.md
---

# Implement API Catalog

Publish an API catalog for automated discovery per
[RFC 9727](https://www.rfc-editor.org/rfc/rfc9727).

## Requirements

- Serve `/.well-known/api-catalog` with `Content-Type: application/linkset+json` and HTTP 200
- Include a `linkset` array with entries for each API
- Each entry needs an `anchor` URL and link relations: `service-desc` (OpenAPI spec), `service-doc` (docs), and optionally `status` (health endpoint)
- See [RFC 9727 Appendix A](https://www.rfc-editor.org/rfc/rfc9727#appendix-A) for examples

## Validate

```
POST https://isitagentready.com/api/scan
Content-Type: application/json

{"url": "https://YOUR-SITE.com"}
```

Check that `checks.discovery.apiCatalog.status` is `"pass"`.
