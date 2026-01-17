# Recommendations for Container Monitoring Clone

## Executive Summary

Based on the comprehensive analysis of CodexBar, this document provides actionable recommendations for building **ContainerBar** - a macOS menu bar application for monitoring Docker containers and Kubernetes clusters.

## Recommended Technology Choices

### Keep from CodexBar

| Technology | Reason |
|------------|--------|
| **Swift 6** | Strict concurrency ensures thread-safety |
| **SwiftPM** | Clean builds, no Xcode dependency |
| **@Observable** | Modern reactive state management |
| **AppKit + SwiftUI** | Menu bar requires AppKit; SwiftUI for views |
| **Sparkle** | Proven auto-update framework |
| **KeyboardShortcuts** | Global hotkey support |

### Replace or Modify

| CodexBar | ContainerBar | Reason |
|----------|--------------|--------|
| SweetCookieKit | Not needed | No browser cookies required |
| Browser detection | Docker/K8s detection | Different connection methods |
| OAuth flows | kubeconfig/docker config | Different auth mechanisms |
| PTY runners | Unix socket/API clients | Direct API access preferred |

### Add New

| Technology | Purpose |
|------------|---------|
| **SwiftNIO** | Async networking for Docker socket |
| **Foundation URLSession** | Kubernetes API calls |
| **Security.framework** | kubeconfig encryption |

## Recommended Module Structure

```
ContainerBar/
├── Package.swift
├── Sources/
│   ├── ContainerBar/              # Main macOS app
│   │   ├── ContainerBarApp.swift
│   │   ├── ContainerStore.swift
│   │   ├── SettingsStore.swift
│   │   ├── StatusItemController.swift
│   │   ├── IconRenderer.swift
│   │   ├── MenuCardView.swift
│   │   ├── PreferencesView.swift
│   │   └── Sources/               # Per-source UI
│   │       ├── Docker/
│   │       └── Kubernetes/
│   ├── ContainerBarCore/          # Business logic
│   │   ├── ContainerFetcher.swift
│   │   ├── SourceDescriptor.swift
│   │   ├── SourceFetchPlan.swift
│   │   └── Sources/
│   │       ├── Docker/
│   │       │   ├── DockerDescriptor.swift
│   │       │   ├── DockerSocketStrategy.swift
│   │       │   ├── DockerAPIStrategy.swift
│   │       │   └── DockerParser.swift
│   │       └── Kubernetes/
│   │           ├── KubernetesDescriptor.swift
│   │           ├── KubeAPIStrategy.swift
│   │           ├── KubectlStrategy.swift
│   │           └── KubernetesParser.swift
│   ├── ContainerBarCLI/           # CLI tool
│   │   └── main.swift
│   └── ContainerBarWidget/        # Desktop widget
│       └── ContainerBarWidget.swift
├── Tests/
├── Scripts/
└── docs/
```

## Recommended Data Sources

### Docker Integration

| Source | Method | Priority |
|--------|--------|----------|
| **Docker Socket** | Unix socket at `/var/run/docker.sock` | Primary |
| **Docker API** | REST API (remote daemon) | Secondary |
| **Docker CLI** | `docker` command output | Fallback |
| **Docker Desktop** | macOS app socket location | macOS-specific |

**Key Docker API Endpoints**:
```
GET /containers/json              # List containers
GET /containers/{id}/stats        # Real-time stats
GET /images/json                  # List images
GET /system/info                  # System info
GET /events                       # Event stream (optional)
```

### Kubernetes Integration

| Source | Method | Priority |
|--------|--------|----------|
| **Kubernetes API** | Direct API server calls | Primary |
| **kubectl** | CLI output parsing | Fallback |
| **Metrics Server** | `/apis/metrics.k8s.io/v1beta1` | Optional |

**Key Kubernetes API Endpoints**:
```
GET /api/v1/pods                  # List pods
GET /api/v1/nodes                 # List nodes
GET /api/v1/namespaces            # List namespaces
GET /apis/metrics.k8s.io/v1beta1/pods    # Pod metrics
GET /apis/metrics.k8s.io/v1beta1/nodes   # Node metrics
```

## Recommended Data Models

### Core Metrics

```swift
public struct ContainerMetrics: Codable, Sendable {
    public let cpuPercent: Double?
    public let memoryUsedBytes: Int?
    public let memoryLimitBytes: Int?
    public let networkRxBytes: Int?
    public let networkTxBytes: Int?
    public let blockReadBytes: Int?
    public let blockWriteBytes: Int?
    public let updatedAt: Date
}

public struct ContainerInfo: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let image: String
    public let status: ContainerStatus
    public let state: ContainerState
    public let ports: [PortMapping]
    public let createdAt: Date
    public let metrics: ContainerMetrics?
}

public enum ContainerStatus: String, Codable, Sendable {
    case running
    case paused
    case exited
    case created
    case restarting
    case removing
    case dead
}
```

### Kubernetes-Specific

```swift
public struct PodInfo: Codable, Sendable, Identifiable {
    public let id: String  // uid
    public let name: String
    public let namespace: String
    public let status: PodPhase
    public let containerStatuses: [PodContainerStatus]
    public let nodeName: String?
    public let createdAt: Date
}

public enum PodPhase: String, Codable, Sendable {
    case pending = "Pending"
    case running = "Running"
    case succeeded = "Succeeded"
    case failed = "Failed"
    case unknown = "Unknown"
}
```

## Recommended UI Design

### Menu Bar Icon

**Options** (configurable):
1. **Dual bars**: CPU % (top) + Memory % (bottom)
2. **Container count badge**: Number of running containers
3. **Health indicator**: Green/yellow/red based on status
4. **Combined**: Icon with count and health color

```
┌──────────────────┐     ┌──────────────────┐
│  ████████░░░░░░  │     │       🐳 12      │
│  ████░░░░░░░░░░  │     │                  │
└──────────────────┘     └──────────────────┘
   CPU + Memory             Docker + Count
```

### Menu Card Design

```
┌─────────────────────────────────────────┐
│ Docker                 Connected (local) │
│ 12 containers • 3 running                │
├─────────────────────────────────────────┤
│ CPU Usage                               │
│ ████████████████░░░░░░░░░░░░░░  45%    │
│ 4.5 cores of 10 available               │
├─────────────────────────────────────────┤
│ Memory Usage                            │
│ ██████████████████░░░░░░░░░░░░  62%    │
│ 4.9 GB of 8 GB                          │
├─────────────────────────────────────────┤
│ Top Containers                          │
│ • nginx        ●  0.5%   128 MB         │
│ • postgres     ●  1.2%   512 MB         │
│ • redis        ●  0.1%   64 MB          │
└─────────────────────────────────────────┘
```

## Recommended Settings Panes

### General Pane
- Refresh frequency (5s, 10s, 30s, 1m, 5m)
- Launch at login
- Show in menu bar (separate/merged icons)

### Sources Pane
- Enable/disable Docker
- Enable/disable Kubernetes
- Connection configuration per source

### Docker Pane
- Socket path (default: /var/run/docker.sock)
- Remote daemon URL (optional)
- Container filter (running only, all)

### Kubernetes Pane
- kubeconfig path
- Context selector
- Namespace filter

### Display Pane
- Metric preference (CPU, Memory, Both)
- Container count threshold for display
- Color thresholds (warning at 80%, critical at 95%)

## Implementation Phases

### Phase 1: Foundation (Week 1-2)
1. Set up SwiftPM project structure
2. Implement basic menu bar status item
3. Create Settings infrastructure
4. Build icon rendering system

### Phase 2: Docker Integration (Week 3-4)
1. Docker socket client
2. Container listing and metrics
3. Docker menu card view
4. Connection status handling

### Phase 3: Kubernetes Integration (Week 5-6)
1. kubeconfig reader
2. Kubernetes API client
3. Pod/node metrics
4. Kubernetes menu card view

### Phase 4: Polish (Week 7-8)
1. WidgetKit extension
2. CLI tool
3. Sparkle auto-updates
4. Documentation and release

## Key Implementation Notes

### Docker Socket Communication

```swift
// Use Unix socket with URLSession
let config = URLSessionConfiguration.default
config.protocolClasses = [UnixSocketURLProtocol.self]

// Or use SwiftNIO for lower-level control
let channel = try await ClientBootstrap(group: eventLoopGroup)
    .connect(unixDomainSocketPath: "/var/run/docker.sock")
```

### Kubernetes Authentication

```swift
// Read kubeconfig
let kubeconfig = try KubeconfigParser.parse(path: "~/.kube/config")
let context = kubeconfig.contexts[kubeconfig.currentContext]

// Extract credentials
// - Bearer token
// - Client certificate
// - Exec credential plugin
```

### Error Handling

Follow CodexBar's patterns:
- Use `ConsecutiveFailureGate` for connection resilience
- Show stale data on first failure
- Surface errors only after consecutive failures
- Provide clear reconnection UI

## Differences from CodexBar

| Aspect | CodexBar | ContainerBar |
|--------|----------|--------------|
| **Data sources** | 16+ AI tools | 2-3 container platforms |
| **Auth complexity** | OAuth, cookies, tokens | Socket, kubeconfig |
| **Refresh rate** | 1-15 minutes | 5-60 seconds |
| **Data volume** | Small (percentages) | Large (metrics streams) |
| **Privacy concerns** | Browser cookies | Local only |

## Success Criteria

1. **Functional**
   - [ ] Connects to local Docker daemon
   - [ ] Displays container list and metrics
   - [ ] Connects to Kubernetes clusters
   - [ ] Shows pod/node status
   - [ ] Auto-updates via Sparkle

2. **Performance**
   - [ ] Refresh completes in <1 second
   - [ ] Memory usage <50 MB
   - [ ] CPU usage <1% idle

3. **User Experience**
   - [ ] Menu opens instantly
   - [ ] Settings persist correctly
   - [ ] Widget displays data
   - [ ] CLI outputs JSON

## Potential Extensions

1. **Docker Compose** - Project-level grouping
2. **Prometheus** - Custom metrics integration
3. **Alerts** - Notification on container crash
4. **Exec** - Quick terminal into container
5. **Logs** - Tail container logs in menu

---

**Summary**: CodexBar provides an excellent foundation for building ContainerBar. The architecture patterns (Provider Descriptor, Fetch Strategy, Observable Store) translate directly. The main differences are simpler authentication (no OAuth/cookies) but more frequent data updates. Recommend starting with Docker socket integration, then adding Kubernetes support.
