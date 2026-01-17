# API Integrations

## Overview

CodexBar integrates with 16+ AI coding tool providers using diverse data collection methods:
- OAuth APIs
- Browser cookie extraction
- CLI RPC/PTY communication
- Manual API tokens
- Local service probes
- Web scraping

Each provider implements one or more **fetch strategies** that are tried in order.

## AI Tool Integrations

### Provider Matrix

| Provider | Auth Method | Data Source | Rate Limits |
|----------|-------------|-------------|-------------|
| **Codex** | OAuth + Cookies | CLI RPC, Web Dashboard | Yes |
| **Claude** | OAuth + Cookies | OAuth API, Web API, CLI PTY | Yes |
| **Cursor** | Browser Cookies | Web API | Yes |
| **Gemini** | OAuth (CLI creds) | Google APIs | Yes |
| **Copilot** | GitHub Device Flow | GitHub API | Yes |
| **z.ai** | API Token | REST API | Yes |
| **Kimi** | JWT Token | REST API | Yes |
| **Kimi K2** | API Key | REST API | Yes |
| **Kiro** | CLI | CLI command output | Yes |
| **Vertex AI** | Google ADC | Cloud Monitoring | Yes |
| **Antigravity** | None (local) | Localhost LSP | Yes |
| **Droid/Factory** | Browser Cookies | Web API + WorkOS | Yes |
| **MiniMax** | Cookies/API Token | Web scrape | Yes |
| **Augment** | Browser Cookies | Web API | Yes |
| **Amp** | Browser Cookies | Web scrape | Yes |

## Integration Patterns

### 1. OAuth API Pattern (Claude, Codex, Gemini)

**Flow**:
```
1. Read credentials from disk (CLI-generated tokens)
2. Refresh if expired
3. Call protected API endpoint
4. Parse response into UsageSnapshot
```

**Claude OAuth Example**:
```swift
// Credential sources (priority order)
// 1. Keychain: "Claude Code-credentials"
// 2. File: ~/.claude/.credentials.json

// API endpoint
GET https://api.anthropic.com/api/oauth/usage
Headers:
  Authorization: Bearer <access_token>
  anthropic-beta: oauth-2025-04-20

// Response mapping
five_hour → session window
seven_day → weekly window
extra_usage → extra usage cost
```

### 2. Browser Cookie Pattern (Cursor, Factory, Augment)

**Flow**:
```
1. Check Keychain cache for valid cookies
2. If missing/expired, import from browsers:
   - Safari: ~/Library/Cookies/Cookies.binarycookies
   - Chrome: ~/Library/Application Support/Google/Chrome/*/Cookies
   - Firefox: ~/Library/Application Support/Firefox/Profiles/*/cookies.sqlite
3. Call web API with Cookie header
4. Parse response
5. Cache cookies in Keychain
```

**Cookie Import Code Path**:
```swift
// BrowserCookieImporter (via SweetCookieKit)
let cookies = try await BrowserCookieImporter.import(
    domain: "cursor.com",
    browsers: settings.browserOrder
)

// Keychain cache
KeychainCacheStore.save(
    service: "com.steipete.codexbar.cache",
    account: "cookie.cursor",
    data: cookieHeaderData
)
```

### 3. CLI RPC/PTY Pattern (Codex, Claude, Kiro)

**RPC Flow** (Codex):
```swift
// Launch RPC server
codex -s read-only -a untrusted app-server

// JSON-RPC messages
→ { "method": "initialize", ... }
← { "result": {...} }
→ { "method": "account/read" }
← { "result": { "email": "...", "plan": "..." } }
→ { "method": "account/rateLimits/read" }
← { "result": { "usage": {...} } }
```

**PTY Flow** (Claude fallback):
```swift
// TTYCommandRunner
runner.send("/usage")
runner.waitForSubstring("Current session")
output = runner.output

// Parse ANSI-stripped text
ClaudeStatusProbe.parse(text: output)
```

### 4. Device Flow OAuth (Copilot)

**Flow**:
```
1. Request device code
   POST https://github.com/login/device/code

2. Show user verification URL
   https://github.com/login/device

3. Poll for token
   POST https://github.com/login/oauth/access_token

4. Store token in Keychain
   Service: com.steipete.CodexBar
   Account: copilot-api-token

5. Use token for API calls
   GET https://api.github.com/copilot_internal/user
```

### 5. API Token Pattern (z.ai, Kimi K2)

**Flow**:
```
1. Read token from:
   - Keychain (user-entered in Settings)
   - Environment variable
2. Call API endpoint
3. Parse response
```

**z.ai Example**:
```swift
// Token sources
// 1. Keychain
// 2. Z_AI_API_KEY env var

// API endpoint
GET https://api.z.ai/api/monitor/usage/quota/limit
Headers:
  Authorization: Bearer <api_token>
```

### 6. Local Probe Pattern (Antigravity)

**Flow**:
```swift
// Antigravity language server detection
// Port 19280-19320 range on localhost HTTPS

// Primary: GetUserStatus
POST https://localhost:19280/cider/v1/GetUserStatus
Body: {}

// Fallback: GetCommandModelConfigs
POST https://localhost:19280/cider/v1/GetCommandModelConfigs
Body: {}
```

## Provider-Specific API Details

### Claude

**OAuth API** (preferred):
```
GET https://api.anthropic.com/api/oauth/usage
Authorization: Bearer <access_token>
anthropic-beta: oauth-2025-04-20

Response:
{
  "five_hour": { "remaining": 88.0, "limit": 100, "reset_at": "..." },
  "seven_day": { "remaining": 63.0, ... },
  "seven_day_sonnet": {...},
  "seven_day_opus": {...}
}
```

**Web API** (cookie fallback):
```
GET https://claude.ai/api/organizations
Cookie: sessionKey=sk-ant-...

GET https://claude.ai/api/organizations/{orgId}/usage
GET https://claude.ai/api/organizations/{orgId}/overage_spend_limit
GET https://claude.ai/api/account
```

### Codex

**OAuth API**:
```
GET https://chatgpt.com/backend-api/wham/usage
Authorization: Bearer <oauth_token>
```

**CLI RPC**:
```json
// Request
{"jsonrpc":"2.0","id":1,"method":"account/rateLimits/read"}

// Response
{
  "primary": {"usedPercent": 28, "windowMinutes": 300, "resetsAt": "..."},
  "secondary": {"usedPercent": 59, ...},
  "credits": {"balance": 112.4}
}
```

### Gemini

**Quota API**:
```
POST https://cloudcode-pa.googleapis.com/v1internal:retrieveUserQuota
Authorization: Bearer <google_oauth_token>
Body: {"project": "<project_id>"}

Response:
{
  "buckets": [
    {"modelId": "gemini-2.0-pro", "remainingFraction": 0.72, "resetTime": "..."},
    {"modelId": "gemini-2.0-flash", "remainingFraction": 0.85, ...}
  ]
}
```

**Token Refresh**:
```
POST https://oauth2.googleapis.com/token
Body: client_id=...&client_secret=...&refresh_token=...&grant_type=refresh_token
```

### Copilot

**Usage API**:
```
GET https://api.github.com/copilot_internal/user
Authorization: token <github_token>
Accept: application/json
Editor-Version: vscode/1.96.2
Editor-Plugin-Version: copilot-chat/0.26.7
X-Github-Api-Version: 2025-04-01

Response:
{
  "copilotPlan": "pro",
  "quotaSnapshots": {
    "premiumInteractions": {"remaining": 80, "limit": 100},
    "chat": {"remaining": 95, "limit": 100}
  }
}
```

## Status Polling

### Statuspage.io Integration

**Providers**: OpenAI, Claude (Anthropic), Cursor, Factory, Copilot (GitHub)

```
GET https://<provider>.statuspage.io/api/v2/status.json

Response:
{
  "status": {
    "indicator": "none|minor|major|critical",
    "description": "All Systems Operational"
  },
  "page": {
    "updated_at": "2025-12-04T18:00:00Z"
  }
}
```

### Google Workspace Incidents

**Providers**: Gemini, Antigravity

```
GET https://www.google.com/appsstatus/dashboard/incidents.json

// Filter by Gemini product ID
// Return most severe active incident
```

## Data Collection Pipeline

### Cookie Import Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                       Cookie Import Pipeline                        │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 1. Check Keychain Cache                                             │
│    - Service: com.steipete.codexbar.cache                          │
│    - Account: cookie.<provider>                                    │
│    - Validate: session not expired                                 │
└────────────────────────────────────┬────────────────────────────────┘
                                     │ miss/expired
                                     ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 2. Import from Browsers (SweetCookieKit)                           │
│    ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐ │
│    │  Safari          │  │  Chrome          │  │  Firefox         │ │
│    │  .binarycookies  │  │  SQLite + DPAPI  │  │  cookies.sqlite  │ │
│    └──────────────────┘  └──────────────────┘  └──────────────────┘ │
└────────────────────────────────────┬────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 3. Build Cookie Header                                             │
│    Cookie: sessionKey=sk-ant-...; cf_clearance=...; __cf_bm=...   │
└────────────────────────────────────┬────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 4. Cache in Keychain for Future Use                                │
│    - Timestamp + source browser                                    │
│    - TTL based on session validity                                 │
└─────────────────────────────────────────────────────────────────────┘
```

### Local Cost Usage Scanning

```
Source Files:
- ~/.codex/sessions/YYYY/MM/DD/*.jsonl (Codex)
- ~/.config/claude/projects/**/*.jsonl (Claude)
- ~/.claude/projects/**/*.jsonl (Claude)

Parse:
- Lines with type: "assistant" and message.usage
- Deduplicate by message.id + requestId (streaming chunks)
- Sum tokens: input, cache_read, cache_creation, output
- Calculate cost using per-model pricing

Cache:
- ~/Library/Caches/CodexBar/cost-usage/claude-v1.json
- ~/Library/Caches/CodexBar/cost-usage/codex-v1.json
- 60s minimum refresh interval
```

## Error Handling

### Retry & Fallback Strategy

```swift
public func fetch(context: ProviderFetchContext, provider: UsageProvider) async -> ProviderFetchOutcome {
    for strategy in strategies {
        // Check availability
        guard await strategy.isAvailable(context) else { continue }

        do {
            let result = try await strategy.fetch(context)
            return .success(result)
        } catch {
            // Check if fallback is allowed
            if strategy.shouldFallback(on: error, context: context) {
                continue  // Try next strategy
            }
            return .failure(error)
        }
    }
    return .failure(.noAvailableStrategy(provider))
}
```

### Rate Limiting

- No explicit rate limiting (relies on provider limits)
- Configurable refresh interval: 1m, 2m, 5m (default), 15m, manual
- 60s minimum for cost usage scanning

### Authentication Errors

| Error | Handling |
|-------|----------|
| Token expired | Auto-refresh via OAuth |
| Cookie invalid | Re-import from browsers |
| API key revoked | Surface error, request new key |
| Login required | Prompt user for login |

## Webhook/Polling Mechanisms

CodexBar uses **polling** exclusively (no WebSockets):

- **Usage polling**: Configurable 1-15 minute intervals
- **Status polling**: Every 5 minutes (when enabled)
- **Cost scanning**: 60-second minimum interval

---

**Summary**: CodexBar implements a comprehensive integration layer supporting OAuth, cookies, CLI communication, and API tokens. The strategy-based fallback system provides resilience when primary data sources fail. For container monitoring, these patterns translate to:
- Docker: Unix socket + REST API
- Kubernetes: kubeconfig + kubectl/API server
- Cloud: OAuth + cloud provider APIs
