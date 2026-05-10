---
name: agent-skills
description: Publish a skills discovery index at `/.well-known/agent-skills/index.json` per the Cloudflare Agent Skills Discovery RFC v0.2.0, listing skills with name, type (`skill-md`/`archive`), description, URL, and SHA-256 digest. Use when exposing reusable agent skills from a site for discovery, building a skills registry endpoint, or validating against isitagentready.com's `agentSkills` check.
metadata:
  tags: agent-skills, well-known, discovery, skills-discovery, cloudflare, rfc
source: https://isitagentready.com/.well-known/agent-skills/agent-skills/SKILL.md
---

# Implement Agent Skills Discovery Index

Publish a skills discovery document per the
[Agent Skills Discovery RFC](https://github.com/cloudflare/agent-skills-discovery-rfc) v0.2.0.

## Requirements

- Serve JSON at `/.well-known/agent-skills/index.json` with HTTP 200
- Include a `$schema` field set to `https://schemas.agentskills.io/discovery/0.2.0/schema.json`
- Include a `skills` array where each entry has:
  - `name` — skill identifier (lowercase alphanumeric + hyphens)
  - `type` — `"skill-md"` (single SKILL.md) or `"archive"` (bundled archive)
  - `description` — brief description of what the skill does
  - `url` — URL to the skill artifact (SKILL.md file or archive)
  - `digest` — SHA-256 hash of the artifact (`sha256:{hex}`)

## Validate

```
POST https://isitagentready.com/api/scan
Content-Type: application/json

{"url": "https://YOUR-SITE.com"}
```

Check that `checks.discovery.agentSkills.status` is `"pass"`.
