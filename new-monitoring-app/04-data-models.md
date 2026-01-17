# Data Models

## Overview

CodexBar uses a well-structured type system with clear separation between:
- **Core Models**: Usage snapshots, rate windows
- **Provider-Specific Models**: Custom data per AI tool
- **Cost/Token Models**: Usage tracking and billing
- **Persistence Models**: Widget and cache storage

All models implement `Sendable` for thread-safety and `Codable` for serialization.

## Core Data Entities

### UsageSnapshot

The primary model representing usage data from any provider.

```swift
public struct UsageSnapshot: Codable, Sendable {
    public let primary: RateWindow?        // Session (5-hour) window
    public let secondary: RateWindow?      // Weekly (7-day) window
    public let tertiary: RateWindow?       // Optional third window (e.g., Opus)
    public let providerCost: ProviderCostSnapshot?
    public let zaiUsage: ZaiUsageSnapshot?
    public let minimaxUsage: MiniMaxUsageSnapshot?
    public let cursorRequests: CursorRequestUsage?
    public let updatedAt: Date
    public let identity: ProviderIdentitySnapshot?
}
```

**Example JSON**:
```json
{
  "primary": {
    "usedPercent": 28.0,
    "windowMinutes": 300,
    "resetsAt": "2025-12-04T19:15:00Z",
    "resetDescription": null
  },
  "secondary": {
    "usedPercent": 59.0,
    "windowMinutes": 10080,
    "resetsAt": "2025-12-05T17:00:00Z"
  },
  "updatedAt": "2025-12-04T18:10:22Z",
  "identity": {
    "providerID": "codex",
    "accountEmail": "user@example.com",
    "loginMethod": "plus"
  }
}
```

### RateWindow

Represents a single rate limit window (session or weekly).

```swift
public struct RateWindow: Codable, Equatable, Sendable {
    public let usedPercent: Double       // 0-100 percent used
    public let windowMinutes: Int?       // Window duration (300 = 5hr, 10080 = 7 days)
    public let resetsAt: Date?           // When the window resets
    public let resetDescription: String? // Human-readable reset text

    // Computed property
    public var remainingPercent: Double {
        max(0, 100 - self.usedPercent)
    }
}
```

### ProviderIdentitySnapshot

Account information associated with a provider.

```swift
public struct ProviderIdentitySnapshot: Codable, Sendable {
    public let providerID: UsageProvider?
    public let accountEmail: String?
    public let accountOrganization: String?
    public let loginMethod: String?  // e.g., "plus", "pro", "team"
}
```

### UsageProvider Enum

All supported providers as a type-safe enum.

```swift
public enum UsageProvider: String, CaseIterable, Codable, Sendable {
    case codex
    case claude
    case gemini
    case antigravity
    case cursor
    case factory
    case zai
    case minimax
    case copilot
    case kimi
    case kimiK2
    case kiro
    case vertexAI
    case augment
    case opencode
    case amp
    case synthetic  // For testing
}
```

## Cost & Token Usage Models

### CostUsageTokenSnapshot

Summary of token usage and costs.

```swift
public struct CostUsageTokenSnapshot: Sendable, Equatable {
    public let sessionTokens: Int?
    public let sessionCostUSD: Double?
    public let last30DaysTokens: Int?
    public let last30DaysCostUSD: Double?
    public let daily: [CostUsageDailyReport.Entry]
    public let updatedAt: Date
}
```

### CostUsageDailyReport

Daily breakdown of token usage and costs.

```swift
public struct CostUsageDailyReport: Sendable, Decodable {
    public struct Entry: Sendable, Decodable, Equatable {
        public let date: String                    // "yyyy-MM-dd"
        public let inputTokens: Int?
        public let cacheReadTokens: Int?
        public let cacheCreationTokens: Int?
        public let outputTokens: Int?
        public let totalTokens: Int?
        public let costUSD: Double?
        public let modelsUsed: [String]?
        public let modelBreakdowns: [ModelBreakdown]?
    }

    public struct ModelBreakdown: Sendable, Decodable, Equatable {
        public let modelName: String
        public let costUSD: Double?
    }

    public struct Summary: Sendable, Decodable, Equatable {
        public let totalInputTokens: Int?
        public let totalOutputTokens: Int?
        public let cacheReadTokens: Int?
        public let cacheCreationTokens: Int?
        public let totalTokens: Int?
        public let totalCostUSD: Double?
    }

    public let data: [Entry]
    public let summary: Summary?
}
```

**Example JSON (CLI cost output)**:
```json
{
  "provider": "claude",
  "source": "local",
  "updatedAt": "2025-12-04T18:10:22Z",
  "sessionTokens": 15000,
  "sessionCostUSD": 0.45,
  "last30DaysTokens": 500000,
  "last30DaysCostUSD": 15.00,
  "daily": [
    {
      "date": "2025-12-04",
      "inputTokens": 10000,
      "outputTokens": 5000,
      "cacheReadTokens": 2000,
      "cacheCreationTokens": 500,
      "totalTokens": 17500,
      "totalCost": 0.45,
      "modelsUsed": ["claude-3-5-sonnet-20241022"]
    }
  ]
}
```

## Credits Models

### CreditsSnapshot

OpenAI credits balance and history.

```swift
public struct CreditsSnapshot: Equatable, Codable, Sendable {
    public let remaining: Double        // Credits remaining
    public let events: [CreditEvent]    // Usage history
    public let updatedAt: Date
}
```

### CreditEvent

Individual credit usage event.

```swift
public struct CreditEvent: Identifiable, Equatable, Codable, Sendable {
    public var id: UUID
    public let date: Date
    public let service: String       // e.g., "CLI", "Code Review"
    public let creditsUsed: Double
}
```

## OpenAI Dashboard Models

### OpenAIDashboardSnapshot

Data scraped from the OpenAI web dashboard.

```swift
public struct OpenAIDashboardSnapshot: Codable, Equatable, Sendable {
    public let signedInEmail: String?
    public let codeReviewRemainingPercent: Double?
    public let creditEvents: [CreditEvent]
    public let dailyBreakdown: [OpenAIDashboardDailyBreakdown]
    public let usageBreakdown: [OpenAIDashboardDailyBreakdown]
    public let creditsPurchaseURL: String?
    public let primaryLimit: RateWindow?
    public let secondaryLimit: RateWindow?
    public let creditsRemaining: Double?
    public let accountPlan: String?
    public let updatedAt: Date
}

public struct OpenAIDashboardDailyBreakdown: Codable, Equatable, Sendable {
    public let day: String                           // "yyyy-MM-dd"
    public let services: [OpenAIDashboardServiceUsage]
    public let totalCreditsUsed: Double
}

public struct OpenAIDashboardServiceUsage: Codable, Equatable, Sendable {
    public let service: String
    public let creditsUsed: Double
}
```

## Widget & Persistence Models

### WidgetSnapshot

Data shared with the WidgetKit extension.

```swift
public struct WidgetSnapshot: Codable, Sendable {
    public let entries: [ProviderEntry]
    public let enabledProviders: [UsageProvider]
    public let generatedAt: Date

    public struct ProviderEntry: Codable, Sendable {
        public let provider: UsageProvider
        public let updatedAt: Date
        public let primary: RateWindow?
        public let secondary: RateWindow?
        public let tertiary: RateWindow?
        public let creditsRemaining: Double?
        public let codeReviewRemainingPercent: Double?
        public let tokenUsage: TokenUsageSummary?
        public let dailyUsage: [DailyUsagePoint]
    }

    public struct TokenUsageSummary: Codable, Sendable {
        public let sessionCostUSD: Double?
        public let sessionTokens: Int?
        public let last30DaysCostUSD: Double?
        public let last30DaysTokens: Int?
    }

    public struct DailyUsagePoint: Codable, Sendable {
        public let dayKey: String      // "yyyy-MM-dd"
        public let totalTokens: Int?
        public let costUSD: Double?
    }
}
```

## Provider-Specific Models

### ProviderStatus

Status polling result for a provider.

```swift
public struct ProviderStatus {
    let indicator: ProviderStatusIndicator
    let description: String?
    let updatedAt: Date?
}

public enum ProviderStatusIndicator: String {
    case none        // Operational
    case minor       // Partial outage
    case major       // Major outage
    case critical    // Critical issue
    case maintenance // Planned maintenance
    case unknown     // Unable to determine
}
```

### Provider Metadata

Configuration metadata for each provider.

```swift
public struct ProviderMetadata: Sendable {
    public let id: UsageProvider
    public let displayName: String          // e.g., "Claude"
    public let sessionLabel: String         // e.g., "Session"
    public let weeklyLabel: String          // e.g., "Weekly"
    public let opusLabel: String?           // e.g., "Opus" for Claude
    public let supportsOpus: Bool
    public let supportsCredits: Bool
    public let creditsHint: String
    public let toggleTitle: String          // Settings toggle text
    public let cliName: String              // CLI argument name
    public let defaultEnabled: Bool
    public let isPrimaryProvider: Bool
    public let usesAccountFallback: Bool
    public let dashboardURL: String?
    public let statusPageURL: String?
}
```

## Data Storage Locations

### File-Based Storage

| Data | Location | Format |
|------|----------|--------|
| Widget snapshot | `~/Library/Group Containers/group.com.steipete.codexbar/widget-snapshot.json` | JSON |
| OpenAI dashboard cache | `~/Library/Application Support/com.steipete.codexbar/openai-dashboard.json` | JSON |
| Cost usage cache | `~/Library/Caches/CodexBar/cost-usage/claude-v1.json` | JSON |
| Token accounts | `~/Library/Application Support/CodexBar/token-accounts.json` | JSON |

### Keychain Storage

| Data | Service | Account |
|------|---------|---------|
| Cookie cache | `com.steipete.codexbar.cache` | `cookie.<provider>` |
| API tokens | Provider-specific | Token identifier |
| Copilot token | App-specific | OAuth token |

### UserDefaults Storage

| Data | Defaults Suite |
|------|---------------|
| App settings | `com.steipete.codexbar` |
| Shared settings | `group.com.steipete.codexbar` |
| Debug settings | `com.steipete.codexbar.debug` |

## Data Validation & Transformation

### Flexible JSON Decoding

Models handle multiple API formats via custom `init(from decoder:)`:

```swift
// Handles both "costUSD" and "totalCost" keys
public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.costUSD =
        try container.decodeIfPresent(Double.self, forKey: .costUSD)
        ?? container.decodeIfPresent(Double.self, forKey: .totalCost)
}
```

### Date Parsing Utilities

```swift
enum CostUsageDateParser {
    static func parse(_ text: String?) -> Date? {
        // Handles: ISO8601 with/without fractional seconds
        // Handles: "yyyy-MM-dd"
        // Handles: "MMM d, yyyy"
    }

    static func parseMonth(_ text: String?) -> Date? {
        // Handles: "MMM yyyy", "MMMM yyyy", "yyyy-MM"
    }
}
```

## Entity Relationships

```
UsageStore (state container)
├── snapshots: [UsageProvider: UsageSnapshot]
│   └── UsageSnapshot
│       ├── primary: RateWindow?
│       ├── secondary: RateWindow?
│       └── identity: ProviderIdentitySnapshot?
├── tokenSnapshots: [UsageProvider: CostUsageTokenSnapshot]
│   └── CostUsageTokenSnapshot
│       └── daily: [CostUsageDailyReport.Entry]
├── credits: CreditsSnapshot?
│   └── events: [CreditEvent]
├── openAIDashboard: OpenAIDashboardSnapshot?
│   └── dailyBreakdown: [OpenAIDashboardDailyBreakdown]
└── statuses: [UsageProvider: ProviderStatus]
```

## Model Design Principles

1. **Immutability**: All models use `let` properties
2. **Sendable**: Thread-safe for Swift 6 concurrency
3. **Codable**: JSON serialization built-in
4. **Equatable**: Enable change detection
5. **Optional fields**: Graceful handling of missing data
6. **Flexible decoding**: Multiple API format support

---

**Summary**: CodexBar's data models are well-designed for a monitoring application. The `RateWindow` and `UsageSnapshot` structures are generic enough to represent container metrics (CPU, memory, network) with minimal changes. The `CostUsageTokenSnapshot` pattern translates to container resource consumption tracking.
