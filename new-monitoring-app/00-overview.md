# CodexBar Repository Overview

## Project Description and Purpose

**CodexBar** is a macOS 14+ menu bar application designed to monitor and display usage quotas and rate limits for various AI coding assistants. The app lives in the system tray (menu bar) and provides at-a-glance visibility into session limits, weekly quotas, and reset timers across multiple AI providers.

### Core Value Proposition

CodexBar solves the problem of "invisible usage limits" that developers face when using AI coding tools. Rather than being surprised by rate limits mid-workflow, developers can:

1. **Monitor multiple AI tools simultaneously** - View Codex, Claude, Cursor, Gemini, Copilot, and 10+ other providers in one place
2. **See real-time quota status** - Session (5-hour) and weekly rate windows displayed as visual progress bars
3. **Get reset timing** - Know exactly when limits refresh (countdown or absolute time)
4. **Track costs** - Local token usage scanning for cost awareness (Codex + Claude)
5. **Stay informed of outages** - Provider status polling with incident badges

### Application Type

- **Platform**: Native macOS (SwiftUI + AppKit hybrid)
- **Distribution**: Direct download, Homebrew Cask, or build from source
- **UI Model**: Menu bar app (LSUIElement) - no Dock icon, minimal UI footprint
- **CLI**: Bundled command-line interface for scripting/CI integration

## Key Features and Functionality

### Multi-Provider Monitoring

| Feature | Description |
|---------|-------------|
| **Provider Toggles** | Enable/disable providers individually (Settings → Providers) |
| **Merge Icons Mode** | Combine all providers into single status item with switcher |
| **Per-Provider Icons** | Separate menu bar icons per enabled provider |
| **Session + Weekly Meters** | Dual progress bars showing 5-hour and 7-day windows |
| **Reset Countdowns** | Time until quota refreshes (configurable: countdown vs clock) |

### Data Sources

CodexBar supports diverse authentication methods depending on the provider:

- **CLI RPC/PTY**: Direct communication with installed CLI tools (Codex, Claude, Gemini)
- **OAuth API**: Token-based API access (Claude, Gemini, Copilot via GitHub)
- **Browser Cookies**: Safari/Chrome/Firefox cookie extraction (Codex web, Cursor, Claude web)
- **API Tokens**: Manual token entry stored in Keychain (z.ai, Kimi, etc.)
- **Local Probes**: Direct localhost communication (Antigravity language server)

### Additional Features

- **WidgetKit Widget**: Mirror menu card data on desktop/notification center
- **Credits Tracking**: OpenAI credits remaining + purchase history
- **Cost Usage Scanning**: Parse local JSONL logs for 30-day token cost breakdown
- **Status Polling**: Check provider status pages (Statuspage.io, Google Workspace)
- **Notifications**: Session quota alerts when thresholds are reached
- **Keyboard Shortcuts**: Quick menu access via customizable hotkey

## Target Users and Use Cases

### Primary Users

1. **Professional Developers** using AI coding assistants daily
2. **Teams** managing shared AI tool subscriptions
3. **DevOps/Automation** needing CLI access to usage data
4. **Cost-conscious Users** tracking token consumption

### Use Cases

- **Quota Management**: Avoid hitting rate limits during critical coding sessions
- **Multi-tool Workflow**: Switch between providers based on remaining quota
- **Budget Tracking**: Monitor credits and costs across AI tools
- **CI/CD Integration**: Query usage via CLI in automation pipelines
- **Incident Awareness**: Know when providers have outages before debugging "why my AI isn't working"

## License Information

```
MIT License
Copyright (c) 2025 Peter Steinberger
```

The project uses the permissive MIT license, allowing:
- Commercial use
- Modification
- Distribution
- Private use

## Contribution Guidelines

While there is no formal CONTRIBUTING.md file, the repository demonstrates professional development practices:

- **Branch-based Development**: Feature branches merged via pull requests
- **Code Style**: SwiftFormat + SwiftLint enforced
- **Testing**: Swift Testing framework with unit tests
- **Documentation**: Extensive docs/ folder with architecture guides

### Provider Authoring

The repository includes a detailed [provider authoring guide](../docs/provider.md) for adding new AI tool integrations:

1. Add `UsageProvider` case to enum
2. Create descriptor with fetch strategies
3. Implement UI hooks (settings/login)
4. Add tests and documentation

## Overall Project Maturity and Activity

### Maturity Indicators

| Indicator | Status |
|-----------|--------|
| **Version** | Active development (0.x series) |
| **Documentation** | Comprehensive (architecture, providers, CLI, release process) |
| **Code Quality** | Swift 6 strict concurrency, SwiftLint enforced |
| **Testing** | Unit tests for parsers and snapshots |
| **Distribution** | GitHub Releases + Homebrew Cask + Linux CLI |
| **Auto-Updates** | Sparkle framework integrated |

### Recent Activity (Last 20 Commits)

The commit history shows active development with features including:

- Synthetic provider support (for testing/mocking)
- Amp provider integration
- Energy/RAM efficiency improvements
- Kimi K2 support
- Claude organization fixes
- Keychain cache store improvements

### Code Statistics

- **231 Swift files** in Sources/
- **8 modules**: CodexBar, CodexBarCore, CodexBarCLI, CodexBarWidget, CodexBarMacros, etc.
- **16+ providers** integrated

## Privacy-First Design

CodexBar emphasizes privacy:

1. **On-device parsing by default** - No data sent to external servers
2. **Browser cookies are opt-in** - User must explicitly enable web features
3. **No password storage** - Reuses existing browser sessions
4. **Known file locations only** - Does not crawl filesystem
5. **No telemetry** - No usage tracking or analytics

### Required Permissions

| Permission | Purpose | When Required |
|------------|---------|---------------|
| Full Disk Access | Read Safari cookies | Optional, for Safari-based providers |
| Keychain Access | Decrypt Chrome cookies, store API tokens | When using Chrome or API tokens |
| Files & Folders | CLI working directories | When CLIs access project folders |

## Inspiration and Credits

CodexBar was inspired by [ccusage](https://github.com/ryoppippi/ccusage) (MIT), specifically the cost usage tracking functionality. The project represents a significant expansion of the original concept into a multi-provider monitoring solution.

---

**Summary**: CodexBar is a mature, actively-developed macOS menu bar application for monitoring AI coding tool usage quotas. Its privacy-first design, multi-provider architecture, and CLI integration make it an excellent reference for building similar monitoring applications.
