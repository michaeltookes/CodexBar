# Reusable Patterns for Container Monitoring

## Overview

This document extracts patterns from CodexBar that are directly applicable to building a Docker/Kubernetes monitoring application. Each pattern includes the original CodexBar implementation and how it maps to container monitoring.

## 1. Provider Descriptor Pattern

### CodexBar Implementation

The Provider Descriptor pattern enables declarative definition of data sources with pluggable fetch strategies.

```swift
public struct ProviderDescriptor: Sendable {
    public let id: UsageProvider
    public let metadata: ProviderMetadata
    public let branding: ProviderBranding
    public let tokenCost: ProviderTokenCostConfig
    public let fetchPlan: ProviderFetchPlan
    public let cli: ProviderCLIConfig
}
```

### Container Monitoring Mapping

```swift
// ContainerSourceDescriptor
public struct ContainerSourceDescriptor: Sendable {
    public let id: ContainerSource      // .docker, .kubernetes, .podman
    public let metadata: SourceMetadata
    public let branding: SourceBranding
    public let fetchPlan: SourceFetchPlan
    public let cli: SourceCLIConfig
}

// Example: Docker source
ContainerSourceDescriptor(
    id: .docker,
    metadata: SourceMetadata(
        displayName: "Docker",
        connectionLabel: "Daemon",
        resourceLabel: "Containers"
    ),
    fetchPlan: SourceFetchPlan(
        sourceModes: [.socket, .api],
        pipeline: SourceFetchPipeline(resolveStrategies: { ctx in
            [DockerSocketStrategy(), DockerAPIStrategy()]
        })
    )
)
```

## 2. Fetch Strategy Pattern

### CodexBar Implementation

```swift
public protocol ProviderFetchStrategy: Sendable {
    var id: String { get }
    var kind: ProviderFetchKind { get }
    func isAvailable(_ context: ProviderFetchContext) async -> Bool
    func fetch(_ context: ProviderFetchContext) async throws -> ProviderFetchResult
    func shouldFallback(on error: Error, context: ProviderFetchContext) -> Bool
}
```

### Container Monitoring Mapping

```swift
// ContainerFetchStrategy
public protocol ContainerFetchStrategy: Sendable {
    var id: String { get }
    var kind: ContainerFetchKind { get }  // .socket, .api, .cli, .ssh
    func isAvailable(_ context: ContainerFetchContext) async -> Bool
    func fetch(_ context: ContainerFetchContext) async throws -> ContainerMetrics
    func shouldFallback(on error: Error, context: ContainerFetchContext) -> Bool
}

// Docker socket strategy
struct DockerSocketStrategy: ContainerFetchStrategy {
    var id: String { "docker-socket" }
    var kind: ContainerFetchKind { .socket }

    func isAvailable(_ context: ContainerFetchContext) async -> Bool {
        FileManager.default.fileExists(atPath: "/var/run/docker.sock")
    }

    func fetch(_ context: ContainerFetchContext) async throws -> ContainerMetrics {
        // Connect to Docker socket
        // Call /containers/json, /containers/{id}/stats
        // Return ContainerMetrics
    }
}
```

## 3. Menu Bar Status Item Pattern

### CodexBar Implementation

```swift
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    var statusItem: NSStatusItem
    var statusItems: [UsageProvider: NSStatusItem] = [:]

    func updateIcons() {
        for provider in settings.enabledProviders {
            let image = IconRenderer.icon(
                primary: snapshot?.primary,
                weekly: snapshot?.secondary,
                stale: isStale,
                indicator: status.indicator
            )
            statusItems[provider]?.button?.image = image
        }
    }
}
```

### Container Monitoring Mapping

```swift
@MainActor
final class ContainerStatusController: NSObject, NSMenuDelegate {
    var statusItem: NSStatusItem
    var sourceItems: [ContainerSource: NSStatusItem] = [:]

    func updateIcons() {
        for source in settings.enabledSources {
            let metrics = store.metrics[source]
            let image = ContainerIconRenderer.icon(
                cpuPercent: metrics?.cpuPercent,
                memoryPercent: metrics?.memoryPercent,
                containerCount: metrics?.runningCount,
                healthStatus: metrics?.overallHealth
            )
            sourceItems[source]?.button?.image = image
        }
    }
}
```

## 4. Snapshot Data Model Pattern

### CodexBar Implementation

```swift
public struct UsageSnapshot: Codable, Sendable {
    public let primary: RateWindow?      // Session usage
    public let secondary: RateWindow?    // Weekly usage
    public let updatedAt: Date
    public let identity: ProviderIdentitySnapshot?
}

public struct RateWindow: Codable, Equatable, Sendable {
    public let usedPercent: Double
    public let windowMinutes: Int?
    public let resetsAt: Date?
}
```

### Container Monitoring Mapping

```swift
public struct ContainerMetrics: Codable, Sendable {
    public let cpuPercent: Double?
    public let memoryPercent: Double?
    public let memoryUsedMB: Double?
    public let memoryLimitMB: Double?
    public let networkRxMB: Double?
    public let networkTxMB: Double?
    public let containerCount: ContainerCount
    public let updatedAt: Date
    public let connection: ConnectionInfo?
}

public struct ContainerCount: Codable, Equatable, Sendable {
    public let running: Int
    public let paused: Int
    public let stopped: Int
    public let total: Int
}

// For Kubernetes
public struct ClusterMetrics: Codable, Sendable {
    public let nodeCount: Int
    public let podCount: PodCount
    public let namespaces: [String]
    public let cpuRequested: Double?
    public let cpuLimit: Double?
    public let memoryRequested: Double?
    public let memoryLimit: Double?
    public let updatedAt: Date
}
```

## 5. Observable State Store Pattern

### CodexBar Implementation

```swift
@MainActor
@Observable
final class UsageStore {
    var snapshots: [UsageProvider: UsageSnapshot] = [:]
    var errors: [UsageProvider: String] = [:]
    var isRefreshing = false
    var refreshingProviders: Set<UsageProvider> = []

    func refresh(force: Bool = false) async {
        self.isRefreshing = true
        defer { self.isRefreshing = false }

        await withTaskGroup(of: Void.self) { group in
            for provider in settings.enabledProviders {
                group.addTask {
                    await self.refreshProvider(provider, force: force)
                }
            }
        }
    }
}
```

### Container Monitoring Mapping

```swift
@MainActor
@Observable
final class ContainerStore {
    var metrics: [ContainerSource: ContainerMetrics] = [:]
    var containers: [ContainerSource: [Container]] = [:]
    var errors: [ContainerSource: String] = [:]
    var isRefreshing = false

    func refresh(force: Bool = false) async {
        self.isRefreshing = true
        defer { self.isRefreshing = false }

        await withTaskGroup(of: Void.self) { group in
            for source in settings.enabledSources {
                group.addTask {
                    await self.refreshSource(source, force: force)
                }
            }
        }
    }
}
```

## 6. Menu Card View Pattern

### CodexBar Implementation

```swift
struct UsageMenuCardView: View {
    struct Model {
        let providerName: String
        let metrics: [Metric]
        let progressColor: Color
    }

    struct Metric: Identifiable {
        let id: String
        let title: String
        let percent: Double
        let resetText: String?
    }
}
```

### Container Monitoring Mapping

```swift
struct ContainerMenuCardView: View {
    struct Model {
        let sourceName: String          // "Docker" / "Kubernetes"
        let connectionStatus: String    // "Connected to local daemon"
        let metrics: [Metric]
        let containers: [ContainerRow]
        let progressColor: Color
    }

    struct Metric: Identifiable {
        let id: String
        let title: String               // "CPU", "Memory", "Network"
        let percent: Double?
        let valueText: String           // "2.3%", "1.2 GB / 8 GB"
    }

    struct ContainerRow: Identifiable {
        let id: String
        let name: String
        let status: ContainerStatus
        let cpuPercent: Double?
        let memoryMB: Double?
    }
}
```

## 7. Settings Persistence Pattern

### CodexBar Implementation

```swift
@MainActor
@Observable
final class SettingsStore {
    var refreshFrequency: RefreshFrequency {
        didSet { userDefaults.set(refreshFrequency.rawValue, forKey: "refreshFrequency") }
    }

    var enabledProviders: Set<UsageProvider> {
        get { /* compute from providerOrderRaw */ }
    }
}
```

### Container Monitoring Mapping

```swift
@MainActor
@Observable
final class ContainerSettingsStore {
    var refreshFrequency: RefreshFrequency {
        didSet { userDefaults.set(refreshFrequency.rawValue, forKey: "refreshFrequency") }
    }

    var enabledSources: Set<ContainerSource> {
        get { /* compute from sourceOrderRaw */ }
    }

    // Docker-specific
    var dockerSocketPath: String {
        didSet { userDefaults.set(dockerSocketPath, forKey: "dockerSocketPath") }
    }

    // Kubernetes-specific
    var kubeconfigPath: String {
        didSet { userDefaults.set(kubeconfigPath, forKey: "kubeconfigPath") }
    }
    var currentContext: String? {
        didSet { userDefaults.set(currentContext, forKey: "kubeContext") }
    }
}
```

## 8. Progress Bar Component Pattern

### CodexBar Implementation

```swift
struct UsageProgressBar: View {
    let percent: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(trackColor)
                Capsule().fill(tint)
                    .frame(width: proxy.size.width * percent / 100)
            }
        }
        .frame(height: 6)
    }
}
```

### Container Monitoring Mapping

```swift
// Same component works for container metrics
struct ResourceProgressBar: View {
    let percent: Double
    let tint: Color
    let warningThreshold: Double = 80
    let criticalThreshold: Double = 95

    var adaptiveTint: Color {
        if percent >= criticalThreshold { return .red }
        if percent >= warningThreshold { return .orange }
        return tint
    }

    var body: some View {
        // Same implementation with adaptive coloring
    }
}
```

## 9. Failure Gate Pattern

### CodexBar Implementation

```swift
struct ConsecutiveFailureGate {
    private(set) var streak: Int = 0

    mutating func recordSuccess() {
        self.streak = 0
    }

    mutating func shouldSurfaceError(onFailureWithPriorData hadPriorData: Bool) -> Bool {
        self.streak += 1
        if hadPriorData, self.streak == 1 { return false }
        return true
    }
}
```

### Container Monitoring Usage

```swift
// Same pattern for container connection resilience
var connectionFailureGates: [ContainerSource: ConsecutiveFailureGate] = [:]

// Use to ignore transient Docker daemon restarts
if failureGate.shouldSurfaceError(onFailureWithPriorData: hadPriorMetrics) {
    errors[source] = error.localizedDescription
}
```

## 10. Icon Renderer Pattern

### CodexBar Implementation

```swift
enum IconRenderer {
    static func icon(
        primary: RateWindow?,
        weekly: RateWindow?,
        stale: Bool,
        indicator: ProviderStatusIndicator
    ) -> NSImage {
        // Render 18x18 @2x template image
        // Dual progress bars
        // Status overlay
    }
}
```

### Container Monitoring Mapping

```swift
enum ContainerIconRenderer {
    static func icon(
        cpuPercent: Double?,
        memoryPercent: Double?,
        containerCount: Int?,
        healthStatus: OverallHealth
    ) -> NSImage {
        // Render 18x18 @2x template image
        // Options:
        // - Dual bars (CPU + Memory)
        // - Container count badge
        // - Health indicator overlay
    }
}
```

## 11. CLI Integration Pattern

### CodexBar Implementation

```swift
// RPC communication
struct CodexRPCClient {
    func call<T: Decodable>(method: String, params: Encodable?) async throws -> T
}

// PTY fallback
struct TTYCommandRunner {
    func send(_ command: String) async
    func waitForSubstring(_ substring: String) async
    var output: String { get }
}
```

### Container Monitoring Mapping

```swift
// Docker CLI integration
struct DockerCLIClient {
    func containers() async throws -> [Container] {
        // docker ps --format json
    }

    func stats() async throws -> [ContainerStats] {
        // docker stats --no-stream --format json
    }
}

// kubectl integration
struct KubectlClient {
    func pods(namespace: String?) async throws -> [Pod] {
        // kubectl get pods -o json
    }

    func topNodes() async throws -> [NodeMetrics] {
        // kubectl top nodes --no-headers
    }
}
```

## 12. Widget Data Sharing Pattern

### CodexBar Implementation

```swift
// App Group for widget communication
let appGroupID = "group.com.steipete.codexbar"

// Shared snapshot
WidgetSnapshotStore.save(snapshot, bundleID: bundleID)

// Widget reads
let snapshot = WidgetSnapshotStore.load()
```

### Container Monitoring Mapping

```swift
// Same pattern
let appGroupID = "group.com.yourcompany.containermonitor"

// Save container metrics for widget
ContainerWidgetStore.save(ContainerWidgetSnapshot(
    sources: enabledSources,
    metrics: currentMetrics,
    containers: topContainers,
    generatedAt: Date()
))
```

## Summary: Pattern Applicability

| CodexBar Pattern | Container Monitoring Application |
|------------------|----------------------------------|
| Provider Descriptor | Container Source Descriptor |
| Fetch Strategy | Docker Socket, K8s API, SSH strategies |
| UsageSnapshot | ContainerMetrics, ClusterMetrics |
| RateWindow | ResourceUsage (CPU%, Mem%, Network) |
| Observable Store | ContainerStore with metrics |
| Menu Card View | Container status card |
| Progress Bar | Resource utilization bars |
| Failure Gate | Connection resilience |
| Icon Renderer | Container health icons |
| Widget Snapshot | Container widget data |

---

**Summary**: CodexBar's architecture is highly transferable to container monitoring. The Provider Descriptor and Fetch Strategy patterns enable clean integration with Docker and Kubernetes APIs. The UI components (menu cards, progress bars, icons) can display container metrics with minimal modification.
