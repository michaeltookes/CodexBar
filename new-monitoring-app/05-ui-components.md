# UI Components

## Overview

CodexBar uses a **hybrid SwiftUI + AppKit** approach:
- **AppKit**: Menu bar status items, menus, window management
- **SwiftUI**: Menu cards, settings panes, visual components

The UI is designed for a menu bar application with minimal footprint and maximum information density.

## Component Inventory

### Core UI Components

#### StatusItemController

**Purpose**: Manages NSStatusItem(s) in the macOS menu bar.

**Location**: `Sources/CodexBar/StatusItemController.swift`

**Features**:
- Multiple status items (one per enabled provider, or merged)
- Dynamic icon rendering
- Menu delegation
- Animation support (blink, wiggle, tilt)
- Keyboard shortcut handling

```swift
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate, StatusItemControlling {
    var statusItem: NSStatusItem
    var statusItems: [UsageProvider: NSStatusItem] = [:]

    // Icon rendering
    func updateIcons() { ... }
    func iconImage(for provider: UsageProvider, ...) -> NSImage { ... }
}
```

#### IconRenderer

**Purpose**: Generates dynamic menu bar icons based on usage data.

**Location**: `Sources/CodexBar/IconRenderer.swift`

**Features**:
- 18×18 template images at 2x resolution
- Dual-bar visualization (session + weekly)
- Stale/error dimming
- Status overlays
- LRU cache for performance

```swift
enum IconRenderer {
    // Icon specifications
    private static let baseSize = NSSize(width: 18, height: 18)
    private static let outputScale: CGFloat = 2

    // Main rendering function
    static func icon(
        primary: RateWindow?,
        weekly: RateWindow?,
        credits: Double?,
        stale: Bool,
        style: IconStyle,
        indicator: ProviderStatusIndicator
    ) -> NSImage { ... }
}
```

**Icon Anatomy**:
```
┌──────────────────┐
│  ████████░░░░░░  │  ← Top bar: Session (5-hour)
│  ██████████░░░░  │  ← Bottom hairline: Weekly
└──────────────────┘
```

### Menu Components

#### MenuCardView (UsageMenuCardView)

**Purpose**: Rich SwiftUI card displayed inside NSMenu.

**Location**: `Sources/CodexBar/MenuCardView.swift`

**Model Structure**:
```swift
struct Model {
    let providerName: String
    let email: String
    let subtitleText: String
    let subtitleStyle: SubtitleStyle  // info, loading, error
    let planText: String?
    let metrics: [Metric]             // Usage rows
    let creditsText: String?
    let tokenUsage: TokenUsageSection?
    let progressColor: Color
}
```

**Visual Layout**:
```
┌─────────────────────────────────────────┐
│ Provider Name                    Email  │
│ Subtitle (last updated / error)         │
├─────────────────────────────────────────┤
│ Session                                 │
│ ████████████████░░░░░░░░░░░░░░  72%    │
│ 72% left          Resets in 2h 15m     │
├─────────────────────────────────────────┤
│ Weekly                                  │
│ ████████████████████░░░░░░░░░░  41%    │
│ 41% left          Resets Fri 9:00 AM   │
├─────────────────────────────────────────┤
│ Credits: 112.4 remaining                │
├─────────────────────────────────────────┤
│ Today: $0.45 (15K tokens)               │
│ Last 30 days: $15.00 (500K tokens)      │
└─────────────────────────────────────────┘
```

#### UsageProgressBar

**Purpose**: Horizontal progress bar for usage visualization.

**Location**: `Sources/CodexBar/UsageProgressBar.swift`

```swift
struct UsageProgressBar: View {
    let percent: Double          // 0-100
    let tint: Color              // Provider brand color
    let accessibilityLabel: String

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(trackColor)      // Background
                Capsule().fill(fillColor)       // Filled portion
                    .frame(width: proxy.size.width * percent / 100)
            }
        }
        .frame(height: 6)
    }
}
```

### Settings/Preferences Components

#### PreferencesView

**Purpose**: Main settings window with tab navigation.

**Location**: `Sources/CodexBar/PreferencesView.swift`

**Tabs**:
| Tab | Component | Purpose |
|-----|-----------|---------|
| General | `GeneralPane` | Refresh frequency, launch at login, display options |
| Providers | `ProvidersPane` | Enable/disable providers, cookie sources |
| Advanced | `AdvancedPane` | CLI install, icon style, personal info hiding |
| About | `AboutPane` | Version info, updates, links |
| Debug | `DebugPane` | Debug options (hidden by default) |

```swift
struct PreferencesView: View {
    @Bindable var settings: SettingsStore
    @Bindable var store: UsageStore
    let updater: UpdaterProviding
    @Bindable var selection: PreferencesSelection

    var body: some View {
        TabView(selection: self.$selection.tab) {
            GeneralPane(...)
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(PreferencesTab.general)
            // ... other tabs
        }
        .frame(width: 500, height: 726)
    }
}
```

#### ProvidersPane

**Purpose**: Provider-specific settings (largest pane).

**Location**: `Sources/CodexBar/PreferencesProvidersPane.swift`

**Per-Provider Settings**:
- Enable/disable toggle
- Cookie source selection (Automatic/Manual)
- Manual token entry
- OAuth login button
- Status indicator

### Chart Components

#### CostHistoryChartMenuView

**Purpose**: Visualize cost/usage over time.

**Location**: `Sources/CodexBar/CostHistoryChartMenuView.swift`

**Features**:
- 30-day history display
- Daily bar chart
- Model breakdown
- Cost summaries

#### CreditsHistoryChartMenuView

**Purpose**: Display credits usage history.

**Location**: `Sources/CodexBar/CreditsHistoryChartMenuView.swift`

#### UsageBreakdownChartMenuView

**Purpose**: Service-level usage breakdown.

**Location**: `Sources/CodexBar/UsageBreakdownChartMenuView.swift`

## UI Patterns

### Menu Bar Patterns

#### Multi-Provider Display

**Separate Icons Mode**:
```
[Codex Icon] [Claude Icon] [Cursor Icon]
```

**Merged Icons Mode**:
```
[Combined Icon] → Dropdown with provider switcher
```

#### Provider Switcher

```swift
struct ProviderSwitcherButtons: View {
    let providers: [UsageProvider]
    @Binding var selected: UsageProvider?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(providers) { provider in
                ProviderButton(provider: provider, selected: $selected)
            }
        }
    }
}
```

### Loading States

```swift
enum SubtitleStyle {
    case info      // Normal state
    case loading   // "Refreshing..."
    case error     // "Failed to fetch"
}
```

**Visual Indicators**:
- Loading: Spinner animation in status bar
- Error: Dimmed icon + red error text
- Stale: Slightly transparent icon

### Error States

**Error Display Pattern**:
```
┌─────────────────────────────────────────┐
│ Claude                                  │
│ ⚠️ Failed to fetch usage               │
│ Error: OAuth token expired              │
│ [Retry] [Copy Error]                   │
└─────────────────────────────────────────┘
```

## Design System

### Provider Branding

Each provider has:
- **Icon**: SVG in `Resources/ProviderIcon-{name}.svg`
- **Color**: RGB defined in `ProviderBranding`

```swift
public struct ProviderBranding: Sendable {
    public let iconStyle: IconStyle
    public let iconResourceName: String
    public let color: ProviderColor
}

public struct ProviderColor: Sendable {
    public let red: CGFloat
    public let green: CGFloat
    public let blue: CGFloat
}
```

**Provider Icons**:
| Provider | Icon File |
|----------|-----------|
| Codex | `ProviderIcon-codex.svg` |
| Claude | `ProviderIcon-claude.svg` |
| Cursor | `ProviderIcon-cursor.svg` |
| Gemini | `ProviderIcon-gemini.svg` |
| Copilot | `ProviderIcon-copilot.svg` |
| ... | ... |

### Color Palette

**System Colors**:
- Primary text: `.primary` (adapts to light/dark)
- Secondary text: `.secondary`
- Progress track: `.gray.opacity(0.2)`
- Progress fill: Provider-specific color

**Highlight Handling**:
```swift
enum MenuHighlightStyle {
    static func primary(_ highlighted: Bool) -> Color { ... }
    static func secondary(_ highlighted: Bool) -> Color { ... }
    static func progressTrack(_ highlighted: Bool) -> Color { ... }
    static func progressTint(_ highlighted: Bool, fallback: Color) -> Color { ... }
}
```

### Typography

| Element | Font | Weight |
|---------|------|--------|
| Provider name | `.title3` | `.semibold` |
| Section title | `.body` | `.medium` |
| Metric value | `.footnote` | `.regular` |
| Reset text | `.footnote` | `.regular` |
| Error text | `.caption` | `.regular` |

### Layout Principles

- **Menu card width**: ~280pt
- **Padding**: 16pt outer, 12pt inner spacing
- **Progress bar height**: 6pt
- **Section spacing**: 12pt

## Accessibility

### VoiceOver Support

```swift
UsageProgressBar(...)
    .accessibilityLabel("Usage remaining")
    .accessibilityValue("\(Int(percent)) percent")
```

### Dynamic Type

SwiftUI views automatically support Dynamic Type. Fixed dimensions used sparingly:
- Menu bar icons: Fixed 18×18 (system requirement)
- Progress bars: Fixed 6pt height

## Animation

### Icon Animations

```swift
enum MotionEffect {
    case blink   // Eyes close/open
    case wiggle  // Horizontal shake
    case tilt    // Rotational tilt
}

struct BlinkState {
    var nextBlink: Date
    var blinkStart: Date?
    var effect: MotionEffect
}
```

### Loading Animation

**Pattern**: Knight Rider style scanning bar

```swift
enum LoadingPattern {
    case knightRider  // Scanning back and forth
    case pulse        // Fade in/out
    case spin         // Rotation
}
```

## Third-Party UI Components

### KeyboardShortcuts

Used for global hotkey configuration in settings.

```swift
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let openMenu = Self("openMenu")
}
```

---

**Summary**: CodexBar's UI is well-structured for a monitoring application. The MenuCardView pattern with its Model struct is highly reusable. For container monitoring, the same card layout can display container metrics (CPU%, memory%, network I/O) instead of token usage. The icon rendering system can be adapted to show container health indicators.
