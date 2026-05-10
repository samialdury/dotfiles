---
name: webmcp
description: Expose site tools to AI agents in the browser via the WebMCP API by calling `navigator.modelContext.registerTool()` with name, description, JSON Schema input, and execute callback. Use when wiring a website's actions (search, navigation, data retrieval) to agentic browsers, integrating WebMCP per the WebML CG draft, managing tool lifecycle with `AbortController`, or validating against isitagentready.com's `webMcp` check.
metadata:
  tags: webmcp, browser, mcp, agents, javascript, navigator, model-context
source: https://isitagentready.com/.well-known/agent-skills/webmcp/SKILL.md
---

# Implement WebMCP

Expose site tools to AI agents via the browser using the
[WebMCP API](https://webmachinelearning.github.io/webmcp/)
([Chrome blog](https://developer.chrome.com/blog/webmcp-epp)).

## Requirements

- Call `navigator.modelContext.registerTool()` for each tool you want to expose
- Each tool needs `name`, `description`, `inputSchema` (JSON Schema), and an `execute` callback
- Tools should expose your site's key actions (search, navigation, data retrieval)
- Use an `AbortController` signal to unregister tools when no longer needed
- The API is detected by loading the page in a browser — ensure the script runs on page load

## Validate

```
POST https://isitagentready.com/api/scan
Content-Type: application/json

{"url": "https://YOUR-SITE.com"}
```

Check that `checks.discovery.webMcp.status` is `"pass"`.
