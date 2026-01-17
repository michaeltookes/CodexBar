# Repository Structure

## Directory Tree Overview

```
CodexBar/
├── .claude/                    # Claude Code settings (IDE integration)
├── .github/
│   └── workflows/              # CI/CD workflows (if any)
├── .swiftpm/                   # Swift Package Manager workspace config
├── bin/                        # Installation scripts
├── docs/                       # Comprehensive documentation
│   ├── refactor/               # Refactoring notes and plans
│   └── screenshots/            # UI screenshots for docs
├── Icon.icon/                  # macOS 14+ icon bundle
│   └── Assets/                 # Icon assets
├── Scripts/                    # Build, release, and utility scripts
├── Sources/                    # Main source code
│   ├── CodexBar/               # Main macOS app (UI + state)
│   ├── CodexBarCLI/            # Command-line interface
│   ├── CodexBarCore/           # Core business logic (shared)
│   ├── CodexBarWidget/         # WidgetKit extension
│   ├── CodexBarMacros/         # Swift macro definitions
│   ├── CodexBarMacroSupport/   # Macro support utilities
│   ├── CodexBarClaudeWatchdog/ # Helper process for Claude CLI
│   └── CodexBarClaudeWebProbe/ # Diagnostic helper for Claude web
├── Tests/                      # macOS tests
│   └── CodexBarTests/          # Unit tests
├── TestsLinux/                 # Linux-specific tests
├── Package.swift               # SwiftPM manifest
├── Package.resolved            # Dependency lock file
├── CHANGELOG.md                # Release notes
├── README.md                   # Project documentation
├── LICENSE                     # MIT License
├── appcast.xml                 # Sparkle update feed
├── version.env                 # Version configuration
└── package.json                # Node.js scripts (docs tooling)
```

## Module Organization (Sources/)

### CodexBar (Main App Target)

**Purpose**: macOS menu bar application - UI, state management, and user interactions.

```
Sources/CodexBar/
├── CodexbarApp.swift           # SwiftUI @main entry point
├── UsageStore.swift            # Central state container (69KB - largest file)
├── SettingsStore.swift         # User preferences (68KB)
├── StatusItemController.swift  # NSStatusItem management
├── StatusItemController+*.swift # Extensions for menu, animation, actions
├── IconRenderer.swift          # Menu bar icon generation (42KB)
├── MenuCardView.swift          # SwiftUI menu card component
├── MenuDescriptor.swift        # Menu item configuration
├── PreferencesView.swift       # Settings window
├── Preferences*Pane.swift      # Settings tabs (General, Providers, Advanced, Debug)
├── ProviderRegistry.swift      # Runtime provider registration
├── *Store.swift                # Token/cookie storage per provider
├── *LoginRunner.swift          # OAuth/login flows
├── Providers/                  # Provider-specific UI implementations
│   ├── Amp/
│   ├── Antigravity/
│   ├── Augment/
│   ├── Claude/
│   ├── Codex/
│   ├── Copilot/
│   ├── Cursor/
│   ├── Factory/
│   ├── Gemini/
│   ├── Kimi/
│   ├── KimiK2/
│   ├── Kiro/
│   ├── MiniMax/
│   ├── OpenCode/
│   ├── Shared/                 # Shared UI components
│   ├── Synthetic/              # Testing/mock provider
│   ├── VertexAI/
│   └── Zai/
└── Resources/                  # App resources (icons, localizations)
```

### CodexBarCore (Shared Library)

**Purpose**: Core business logic shared between app, CLI, and widget. Contains fetch logic, parsers, and data models.

```
Sources/CodexBarCore/
├── UsageFetcher.swift          # Main usage fetching coordinator
├── CostUsageFetcher.swift      # Local log scanner
├── CostUsageModels.swift       # Token cost data structures
├── BrowserDetection.swift      # Browser detection utilities
├── BrowserCookieImportOrder.swift
├── CookieHeader*.swift         # Cookie parsing utilities
├── KeychainCacheStore.swift    # Secure storage
├── PathEnvironment.swift       # Environment path handling
├── TextParsing.swift           # CLI output parsers
├── TokenAccounts.swift         # Multi-account support
├── UsageFormatter.swift        # Output formatting
├── WidgetSnapshot.swift        # Widget data structure
├── Host/                       # Host system APIs
│   ├── Process/                # Subprocess execution
│   │   └── SubprocessRunner.swift
│   └── PTY/                    # Pseudo-terminal handling
│       ├── TTYCommandRunner.swift
│       └── PTYUtils.swift
├── Logging/                    # Logging infrastructure
│   └── CodexBarLog.swift
├── OpenAIWeb/                  # OpenAI web dashboard scraping
│   └── OpenAIDashboardFetcher.swift
├── Providers/                  # Provider implementations (fetch logic)
│   ├── ProviderDescriptor.swift     # Provider definition protocol
│   ├── ProviderFetchPlan.swift      # Fetch strategy system
│   ├── Providers.swift              # UsageProvider enum
│   ├── ProviderTokenResolver.swift  # Token resolution
│   ├── Amp/
│   │   ├── AmpDescriptor.swift
│   │   ├── AmpStrategies.swift
│   │   ├── AmpFetcher.swift
│   │   └── AmpParser.swift
│   ├── Claude/
│   │   ├── ClaudeOAuth/             # OAuth implementation
│   │   └── ClaudeWeb/               # Web API fetching
│   ├── Codex/
│   │   └── CodexOAuth/
│   ├── (other providers...)
│   └── VertexAI/
│       └── VertexAIOAuth/
├── Vendored/                   # Third-party code
│   └── CostUsage/              # Cost calculation logic
└── WebKit/                     # WebKit integration
```

### CodexBarCLI (Command-Line Interface)

**Purpose**: Standalone CLI for scripting and CI/CD integration.

```
Sources/CodexBarCLI/
└── main.swift                  # Commander-based CLI entry
```

### CodexBarWidget (WidgetKit Extension)

**Purpose**: Desktop/notification center widget mirroring menu card data.

```
Sources/CodexBarWidget/
├── CodexBarWidget.swift        # Widget entry point
└── WidgetViews.swift           # Widget UI components
```

### Supporting Modules

```
Sources/CodexBarMacros/         # Swift macro definitions
├── ProviderDescriptorMacro.swift
└── ProviderImplementationMacro.swift

Sources/CodexBarMacroSupport/   # Macro runtime support
├── MacroSupport.swift
└── Registrations.swift

Sources/CodexBarClaudeWatchdog/ # Helper to clean up Claude CLI processes
└── main.swift

Sources/CodexBarClaudeWebProbe/ # Diagnostic tool for Claude web
└── main.swift
```

## Configuration Files

### Package.swift (SwiftPM Manifest)

Key characteristics:
- **Swift Tools Version**: 6.2
- **Platform**: macOS 14+
- **Strict Concurrency**: Enabled for all targets
- **Conditional Compilation**: macOS-specific targets excluded on Linux

### Build & Deployment Files

| File | Purpose |
|------|---------|
| `version.env` | MARKETING_VERSION and BUILD_NUMBER |
| `.swiftformat` | Code formatting rules |
| `.swiftlint.yml` | Linting configuration |
| `.gitignore` | Git ignore patterns |
| `appcast.xml` | Sparkle auto-update feed |

### Documentation Structure

```
docs/
├── architecture.md             # Module and data flow overview
├── providers.md                # Provider data sources
├── provider.md                 # Provider authoring guide
├── refresh-loop.md             # Refresh cadence details
├── status.md                   # Status polling documentation
├── ui.md                       # UI and icon details
├── cli.md                      # CLI reference
├── widgets.md                  # WidgetKit documentation
├── RELEASING.md                # Release checklist
├── DEVELOPMENT_SETUP.md        # Developer setup
├── (provider-specific docs)    # claude.md, codex.md, cursor.md, etc.
└── refactor/                   # Refactoring plans
```

## Scripts Directory

```
Scripts/
├── compile_and_run.sh          # Development build + run
├── package_app.sh              # App bundle creation (380 lines)
├── sign-and-notarize.sh        # Code signing + Apple notarization
├── release.sh                  # Full release automation
├── make_appcast.sh             # Generate Sparkle appcast
├── build_icon.sh               # Icon conversion
├── verify_appcast.sh           # Validate appcast signatures
├── changelog-to-html.sh        # Convert changelog to HTML
├── check_upstreams.sh          # Check upstream changes
├── check-release-assets.sh     # Verify GitHub release assets
├── setup_dev_signing.sh        # Developer signing setup
├── launch.sh                   # Quick launch script
└── docs-list.mjs               # Documentation indexer (Node.js)
```

## Organization Pattern

### Feature-Based with Layer Separation

CodexBar uses a **hybrid feature + layer** organization:

1. **Layer Separation (Top Level)**
   - `CodexBarCore`: Business logic, data fetching, models
   - `CodexBar`: UI components, state management
   - `CodexBarCLI`: CLI interface
   - `CodexBarWidget`: Widget extension

2. **Feature-Based (Within Layers)**
   - Providers organized by name under `Providers/` directories
   - Each provider has its own subfolder with descriptor, strategies, fetcher, parser

### Provider Architecture (Key Pattern)

```
Provider in CodexBarCore/Providers/      Provider in CodexBar/Providers/
┌─────────────────────────────────┐     ┌────────────────────────────────┐
│ *Descriptor.swift               │     │ *ProviderImplementation.swift  │
│ - ProviderDescriptor definition │     │ - UI hooks only                │
│ *Strategies.swift               │     │ - Settings pane components     │
│ - Fetch strategy implementations│     │ - Login flow UI                │
│ *Fetcher.swift                  │     │                                │
│ - API/CLI communication         │     │                                │
│ *Parser.swift                   │     │                                │
│ - Response parsing              │     │                                │
│ *Models.swift                   │     │                                │
│ - Data structures               │     │                                │
└─────────────────────────────────┘     └────────────────────────────────┘
```

## Notable Files by Size/Importance

| File | Size | Role |
|------|------|------|
| `UsageStore.swift` | 69KB | Central state management |
| `SettingsStore.swift` | 68KB | User preferences persistence |
| `StatusItemController+Menu.swift` | 47KB | Menu construction |
| `IconRenderer.swift` | 42KB | Dynamic icon generation |
| `PreferencesProvidersPane.swift` | 41KB | Provider settings UI |
| `MenuCardView.swift` | 37KB | Usage display card |
| `StatusItemController+SwitcherViews.swift` | 32KB | Provider switcher UI |
| `UsageFetcher.swift` | 24KB | Fetch coordination |

## Testing Structure

```
Tests/
└── CodexBarTests/
    └── (macOS unit tests)

TestsLinux/
└── (Linux-compatible tests)
```

Tests focus on:
- Snapshot parsing
- Strategy availability
- CLI argument handling
- Provider registration

---

**Summary**: The repository follows a clean modular architecture with clear separation between UI (CodexBar), business logic (CodexBarCore), and auxiliary tools (CLI, Widget). The provider system is particularly well-organized, making it straightforward to add new integrations by following the established pattern.
