---
name: oauth-discovery
description: Publish OAuth 2.0 / OpenID Connect discovery metadata at `/.well-known/openid-configuration` (OIDC) or `/.well-known/oauth-authorization-server` (OAuth) per RFC 8414 and OIDC Discovery, with `issuer`, `authorization_endpoint`, `token_endpoint`, `jwks_uri`, and supported grant/response types. Use when exposing an authorization server for agent authentication, configuring Cloudflare Access as IdP, or validating against isitagentready.com's `oauthDiscovery` check.
metadata:
  tags: oauth, oidc, openid-connect, rfc8414, discovery, well-known, jwks, cloudflare
source: https://isitagentready.com/.well-known/agent-skills/oauth-discovery/SKILL.md
---

# Implement OAuth/OIDC Discovery

Publish OAuth or OpenID Connect discovery metadata so agents can authenticate
with your APIs.
See [OpenID Connect Discovery](http://openid.net/specs/openid-connect-discovery-1_0.html)
and [RFC 8414](https://www.rfc-editor.org/rfc/rfc8414).

## Requirements

- Serve JSON at `/.well-known/openid-configuration` (OIDC) or `/.well-known/oauth-authorization-server` (OAuth 2.0)
- Include `issuer`, `authorization_endpoint`, `token_endpoint`, `jwks_uri`
- List `grant_types_supported` and `response_types_supported`

## Cloudflare

[Cloudflare Access](https://developers.cloudflare.com/cloudflare-one/identity/)
can serve as an identity provider, or use Workers to proxy discovery metadata.

## Validate

```
POST https://isitagentready.com/api/scan
Content-Type: application/json

{"url": "https://YOUR-SITE.com"}
```

Check that `checks.discovery.oauthDiscovery.status` is `"pass"`.
