# Technology Stack

## Overview

CodexBar is built as a **native macOS application** using modern Apple frameworks and Swift. It prioritizes Swift 6 strict concurrency for thread-safety and uses SwiftPM for dependency management.

## Language & Runtime

| Technology | Version | Purpose |
|------------|---------|---------|
| **Swift** | 6.2+ | Primary language with strict concurrency |
| **macOS SDK** | 14.0+ (Sonoma) | Minimum deployment target |
| **Linux** | - | CLI-only support via conditional compilation |

### Swift 6 Strict Concurrency

The project enforces strict concurrency throughout:

```swift
// Package.swift
.enableUpcomingFeature("StrictConcurrency")
```

Key concurrency patterns used:
- `@MainActor` for UI state
- `Sendable` conformance for shared data
- Explicit actor isolation
- `nonisolated` for background work

## Framework Dependencies

### Core Dependencies

| Package | Version | Purpose | URL |
|---------|---------|---------|-----|
| **Sparkle** | 2.8.1+ | Auto-updates | sparkle-project/Sparkle |
| **Commander** | 0.2.0+ | CLI argument parsing | steipete/Commander |
| **swift-log** | 1.8.0+ | Structured logging | apple/swift-log |
| **swift-syntax** | 600.0.0+ | Swift macros | apple/swift-syntax |
| **KeyboardShortcuts** | 1.10.0+ | Global hotkey handling | sindresorhus/KeyboardShortcuts |
| **SweetCookieKit** | 0.2.0+ | Browser cookie extraction | steipete/SweetCookieKit |

### Dependency Analysis

```swift
// Package.swift - Key dependencies
.package(url: "https://github.com/sparkle-project/Sparkle", from: "2.8.1"),
.package(url: "https://github.com/steipete/Commander", from: "0.2.0"),
.package(url: "https://github.com/apple/swift-log", from: "1.8.0"),
.package(url: "https://github.com/apple/swift-syntax", from: "600.0.0"),
.package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "1.10.0"),
// SweetCookieKit - local or remote based on env var
```

## Apple Frameworks

### UI Frameworks

| Framework | Usage |
|-----------|-------|
| **SwiftUI** | Settings window, menu cards, preferences panes |
| **AppKit** | NSStatusItem (menu bar), NSMenu, NSImage rendering |
| **QuartzCore** | Display link for animations (CADisplayLink) |
| **WidgetKit** | Desktop widget extension |

### System Frameworks

| Framework | Usage |
|-----------|-------|
| **Foundation** | Core utilities, JSON parsing, networking |
| **Security** | Keychain access, code signing verification |
| **ServiceManagement** | Launch at login functionality |
| **WebKit** | WKWebView for OAuth flows and web scraping |

### Framework Integration Pattern

CodexBar uses a **hybrid SwiftUI + AppKit** approach:

```swift
// Entry point (SwiftUI)
@main
struct CodexBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    // ...
}

// Menu bar management (AppKit)
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    var statusItem: NSStatusItem
    // Dynamic icon rendering via NSImage
}

// Settings/Preferences (SwiftUI)
Settings {
    PreferencesView(...)
}
```

## Build System

### Swift Package Manager (SwiftPM)

The project uses SwiftPM exclusively (no Xcode project file):

```swift
// Package.swift
let package = Package(
    name: "CodexBar",
    platforms: [.macOS(.v14)],
    // ...
)
```

**Benefits**:
- Cross-platform compilation (Linux CLI)
- Clean dependency management
- Script-based build/packaging

### Build Configuration

| File | Purpose |
|------|---------|
| `Package.swift` | SwiftPM manifest with multi-target definitions |
| `Package.resolved` | Dependency lock file |
| `version.env` | Version variables (MARKETING_VERSION, BUILD_NUMBER) |

### Conditional Compilation

```swift
// Target-specific code
#if os(macOS)
targets.append(contentsOf: [
    .executableTarget(name: "CodexBar", ...),
    .executableTarget(name: "CodexBarWidget", ...),
])
#endif

// Feature flags
#if canImport(Sparkle) && ENABLE_SPARKLE
import Sparkle
// Sparkle integration
#endif
```

## Development Tools

### Code Formatting (SwiftFormat)

**Configuration**: `.swiftformat`

Key settings:
```
--swiftversion 6.2
--self insert              # Required for Swift 6 concurrency
--indent 4
--maxwidth 120
--wraparguments before-first
--organizetypes class,struct,enum,extension
```

### Linting (SwiftLint)

**Configuration**: `.swiftlint.yml`

Features enabled:
- Analyzer rules (unused_declaration, unused_import)
- Opt-in rules (array_init, closure_spacing, first_where, etc.)
- Custom thresholds for function_body_length, file_length, cyclomatic_complexity

Disabled for Swift 6 compatibility:
- `explicit_self` (Swift 6 requires self)
- SwiftFormat-handled rules (trailing_whitespace, etc.)

### Testing Framework

```swift
// Swift Testing (modern)
.enableExperimentalFeature("SwiftTesting")

// Tests/CodexBarTests/
// TestsLinux/ (Linux-compatible subset)
```

## Networking & Data

### Network Stack

| Component | Technology |
|-----------|------------|
| HTTP Client | URLSession (Foundation) |
| Cookie Management | SweetCookieKit + custom cookie parsers |
| OAuth | Manual implementation (device flow, token refresh) |
| WebSocket | Not used (polling-based architecture) |

### Data Serialization

| Format | Usage |
|--------|-------|
| **JSON** | API responses, settings persistence |
| **JSONL** | Log file parsing (cost usage) |
| **Property Lists** | macOS preferences (UserDefaults) |
| **Keychain** | Secure token storage |
| **HTML** | Web scraping (various providers) |

### Cookie Sources

```swift
// SweetCookieKit integration
.product(name: "SweetCookieKit", package: "SweetCookieKit")

// Browser support:
// - Safari: ~/Library/Cookies/Cookies.binarycookies
// - Chrome: ~/Library/Application Support/Google/Chrome/*/Cookies
// - Firefox: ~/Library/Application Support/Firefox/Profiles/*/cookies.sqlite
```

## CLI Technology

### Commander Framework

The CLI uses a custom fork of Commander for argument parsing:

```swift
// Sources/CodexBarCLI/main.swift
import Commander

Group {
    $0.command("usage", ...) { ... }
    $0.command("cost", ...) { ... }
}
```

Features:
- Subcommand routing
- Flag/option parsing
- Help text generation
- ANSI color output (TTY-aware)

## Macro System

### Swift Macros for Provider Registration

```swift
// CodexBarMacros - SwiftSyntax-based macros
.macro(
    name: "CodexBarMacros",
    dependencies: [
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
    ])

// Usage
@ProviderDescriptorRegistration
@ProviderDescriptorDefinition
public enum ExampleProviderDescriptor {
    static func makeDescriptor() -> ProviderDescriptor { ... }
}
```

## Version & Update System

### Sparkle Integration

```swift
// Conditional import
#if canImport(Sparkle) && ENABLE_SPARKLE
import Sparkle

@MainActor
final class SparkleUpdaterController: NSObject, UpdaterProviding, SPUUpdaterDelegate {
    // ...
}
#endif
```

Configuration:
- `SUFeedURL`: appcast.xml URL
- `SUPublicEDKey`: Ed25519 public key for signature verification
- `SUEnableAutomaticChecks`: Auto-update preference

## Summary: Technology Choices

### Why These Technologies?

| Choice | Rationale |
|--------|-----------|
| **Native Swift** | Best macOS integration, system tray support |
| **SwiftUI + AppKit** | Modern UI with full system access |
| **SwiftPM** | Clean builds, Linux support, no Xcode dependency |
| **Swift 6** | Compile-time concurrency safety |
| **Sparkle** | Industry-standard macOS auto-updates |
| **swift-syntax** | Compile-time macro code generation |

### Technology Applicability for Container Monitoring

| CodexBar Tech | Container Monitor Equivalent |
|---------------|------------------------------|
| Browser cookies | Docker socket / kubeconfig |
| OAuth flows | Kubernetes RBAC / service accounts |
| Statuspage.io polling | Prometheus/AlertManager |
| JSONL log parsing | Container log streaming |
| Menu bar UI | Identical pattern applies |
| WidgetKit | Identical pattern applies |

---

**Summary**: CodexBar uses a modern Swift 6 stack with strict concurrency, SwiftPM for builds, and a hybrid SwiftUI/AppKit UI. The technology choices are well-suited for a macOS monitoring application and translate directly to container/Kubernetes monitoring use cases.
