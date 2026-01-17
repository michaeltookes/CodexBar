# Design Document Agent Instructions

## Mission
Read and synthesize all analysis findings from the `new-monitoring-app/` folder (created by the analysis agent) and create a comprehensive design document for a macOS menu bar application that monitors Docker containers. This design document must be detailed enough for another agent to implement the application without ambiguity.

## Input Required
- All markdown files in the `new-monitoring-app/` folder (analysis of CodexBar)
- These instructions

## Output Required
A single comprehensive design document: `new-monitoring-app/DESIGN_DOCUMENT.md`

This document will serve as the complete blueprint for building the Docker monitoring menu bar application.

---

## Application Overview

### Product Vision
A lightweight macOS menu bar application (similar to CodexBar) that provides quick access to Docker container status and management. The app eliminates the need to keep Portainer or Docker Desktop open in a browser window, instead providing instant access to container information and controls from the macOS menu bar.

### Target User
- **Primary User**: Single developer/DevOps engineer managing Docker containers on a remote server
- **Use Case**: Quick monitoring and basic management of Docker containers without opening a full browser-based UI
- **Platform**: macOS (menu bar application)

### Core Value Proposition
"Monitor and manage your Docker containers from your macOS menu bar - no browser required."

---

## MVP Feature Set

### Primary Features (MVP - Must Have)

**1. Menu Bar Presence**
- Always-visible icon in macOS menu bar
- Icon should indicate overall system health at a glance
- Click to reveal dropdown menu with container information

**2. Container Status Display**
- Show all containers with their current status (running/stopped/paused/restarting)
- Display key metrics when user clicks on a container:
  - CPU usage percentage
  - Memory usage (used/limit)
  - Network I/O
  - Container uptime
  - Container name and image

**3. Basic Container Controls (Menu Items)**
All actions available as menu items under each container:
- Start container
- Stop container
- Restart container
- View logs (open in separate window or default log viewer)
- Remove container (with confirmation)

**4. Refresh & Settings**
- Manual refresh option
- Configurable auto-refresh interval (in advanced settings)
- Settings to configure Docker host connection

**5. Docker Host Configuration**
- Support connection to remote Docker daemon (Beelink server)
- Connection methods:
  - TCP with TLS
  - SSH tunnel
  - Unix socket (for local Docker)
- Store connection credentials securely in macOS keychain

### Secondary Features (Roadmap - Future Versions)

**Phase 2:**
- Multi-host support (manage multiple Docker servers)
- Container creation from images
- Image management (pull/remove)
- Volume and network management
- Compose stack management

**Phase 3:**
- Podman support
- Kubernetes cluster monitoring
- Alerts and notifications for container failures
- Container resource limit configuration
- Export/import container configurations

---

## Technical Requirements

### Platform & Framework
**Based on CodexBar Analysis:**
- **Platform**: macOS menu bar application
- **Language**: Swift
- **Framework**: macOS SDK (AppKit/SwiftUI)
- **Minimum macOS Version**: [Extract from CodexBar analysis]

**Note to Design Agent**: Review the tech stack analysis (`02-tech-stack.md`) and specify:
- Exact Swift version used in CodexBar
- Whether CodexBar uses SwiftUI, AppKit, or both
- Any third-party Swift dependencies worth considering
- Build system (Xcode, Swift Package Manager)

### Docker Integration
**Docker API Requirements:**
- Connect to Docker Engine API (REST API over HTTP/HTTPS)
- API Version: Use latest stable Docker Engine API (v1.43+)
- Required API endpoints:
  - `/containers/json` - List containers
  - `/containers/{id}/stats` - Get container statistics (streaming)
  - `/containers/{id}/start` - Start container
  - `/containers/{id}/stop` - Stop container
  - `/containers/{id}/restart` - Restart container
  - `/containers/{id}/logs` - Get container logs
  - `/containers/{id}` - Remove container
  - `/_ping` - Health check

**Connection Security:**
- Support TLS for remote connections
- SSH tunneling as alternative
- Credential storage in macOS Keychain

**Performance Considerations:**
- Use streaming stats endpoint for real-time metrics
- Implement connection pooling
- Cache container list, refresh on interval
- Handle network timeouts gracefully

---

## Design Document Structure

The design document (`DESIGN_DOCUMENT.md`) must include the following sections:

### Section 1: Executive Summary
- Brief overview of the application (2-3 paragraphs)
- Key objectives and success criteria
- Target user and primary use case

### Section 2: Architecture Overview

**2.1 Application Architecture**
- High-level architecture diagram (use Mermaid or ASCII art)
- Component breakdown:
  - Menu bar UI layer
  - Docker API client layer
  - Data models and state management
  - Settings and configuration management
  - Security/credential management

**2.2 Architecture Patterns from CodexBar**
Based on `03-architecture-patterns.md`, document:
- Which architectural patterns from CodexBar apply directly
- Which patterns need modification for Docker monitoring
- New patterns required for Docker-specific features

**2.3 Data Flow**
- How data flows from Docker API → App State → UI
- Real-time update mechanism
- Error handling and retry logic

### Section 3: Technical Stack

**3.1 Core Technologies**
Based on `02-tech-stack.md`:
- Programming language and version
- Frameworks (UI, networking, etc.)
- Build tools and dependencies
- Testing frameworks

**3.2 Third-Party Libraries**
Recommended libraries for:
- HTTP client for Docker API
- JSON parsing
- Secure credential storage
- Logging and debugging
- (Extract any relevant libraries CodexBar uses that could apply)

### Section 4: Data Models

**4.1 Core Data Structures**
Define all data models needed:

```swift
// Example structure - expand based on Docker API responses
struct DockerContainer {
    let id: String
    let name: String
    let image: String
    let status: ContainerStatus
    let state: ContainerState
    let created: Date
    // ... additional properties
}

struct ContainerStats {
    let cpuUsage: Double
    let memoryUsage: UInt64
    let memoryLimit: UInt64
    let networkRx: UInt64
    let networkTx: UInt64
    let timestamp: Date
}

enum ContainerStatus {
    case running
    case stopped
    case paused
    case restarting
    case dead
}

struct DockerHost {
    let id: UUID
    let name: String
    let connectionType: ConnectionType
    let endpoint: String
    // ... connection details
}
```

**4.2 State Management**
Based on `07-state-management.md`:
- How CodexBar manages state (adapt for Docker monitoring)
- App-wide state structure
- State update patterns
- Persistence strategy (what state to save/restore)

### Section 5: User Interface Design

**5.1 Menu Bar Icon**
- Design requirements for the icon
- Icon states (idle, active, error, updating)
- Animation considerations

**5.2 Dropdown Menu Structure**
Based on `05-ui-components.md`, design:

```
┌─────────────────────────────────────┐
│ 🐳 Docker Monitor                   │
├─────────────────────────────────────┤
│ Connected to: beelink-server        │
│ ○ 8 running  ○ 2 stopped  ○ 2 paused│
├─────────────────────────────────────┤
│ ▸ nginx-proxy          [Running]    │
│   CPU: 2.3%  MEM: 128MB             │
│   ├─ View Details                   │
│   ├─ Stop                           │
│   ├─ Restart                        │
│   ├─ View Logs                      │
│   └─ Remove...                      │
│                                      │
│ ▸ postgres-db          [Running]    │
│   CPU: 5.1%  MEM: 512MB             │
│   └─ ... (same submenu)             │
│                                      │
│ ▸ redis-cache          [Stopped]    │
│   └─ Start                          │
│   └─ Remove...                      │
├─────────────────────────────────────┤
│ ⟳ Refresh Now                       │
│ ⚙️ Settings...                      │
│ ❌ Quit                             │
└─────────────────────────────────────┘
```

**5.3 Settings Window**
- Docker host configuration UI
- Connection settings (host, port, TLS options)
- Refresh interval configuration
- General preferences

**5.4 UI Components to Reuse**
From CodexBar's `05-ui-components.md`:
- Identify reusable UI patterns (list items, status indicators, etc.)
- Document what needs to be adapted vs. built new

### Section 6: API Integration Layer

**6.1 Docker API Client Design**
```swift
// Pseudo-code structure
protocol DockerAPIClient {
    func listContainers() async throws -> [DockerContainer]
    func getContainerStats(id: String) async throws -> ContainerStats
    func startContainer(id: String) async throws
    func stopContainer(id: String) async throws
    func restartContainer(id: String) async throws
    func getContainerLogs(id: String) async throws -> String
    func removeContainer(id: String) async throws
}

class DockerAPIClientImpl: DockerAPIClient {
    // Implementation details
    // Connection management
    // Request/response handling
    // Error handling
}
```

**6.2 Connection Management**
- Connection initialization and teardown
- TLS certificate handling
- SSH tunnel setup (if using SSH)
- Connection health monitoring
- Reconnection logic on failure

**6.3 Authentication & Security**
- How to securely store Docker host credentials
- TLS certificate validation
- SSH key management
- Keychain integration

**6.4 Error Handling Strategy**
- Network errors (timeout, connection refused, etc.)
- API errors (unauthorized, not found, etc.)
- User-facing error messages
- Retry logic and exponential backoff

### Section 7: Real-time Updates

**7.1 Update Strategy**
- Polling interval (configurable, default: 5 seconds)
- Streaming stats vs. polling
- Efficient delta updates (only update changed containers)

**7.2 Performance Optimization**
- Minimize API calls
- Cache container list
- Debounce rapid updates
- Background vs. foreground update behavior

### Section 8: Settings & Configuration

**8.1 Configuration Data Model**
```swift
struct AppSettings {
    var dockerHosts: [DockerHost]
    var selectedHostId: UUID?
    var refreshInterval: TimeInterval
    var showCPUInMenuBar: Bool
    var showMemoryInMenuBar: Bool
    // ... other preferences
}
```

**8.2 Persistence**
- UserDefaults for app preferences
- Keychain for credentials
- What to persist vs. what's ephemeral

**8.3 Settings UI**
- Connection settings panel
- Refresh/update preferences
- Advanced options

### Section 9: Build & Development Setup

**9.1 Development Environment**
Based on `08-build-and-deployment.md`:
- Xcode version requirements
- Swift Package Manager dependencies
- Build configurations (Debug/Release)
- Code signing requirements

**9.2 Project Structure**
Recommended directory structure:
```
DockerMonitor/
├── DockerMonitor/
│   ├── App/
│   │   ├── AppDelegate.swift
│   │   └── MenuBarController.swift
│   ├── Models/
│   │   ├── DockerContainer.swift
│   │   ├── ContainerStats.swift
│   │   └── DockerHost.swift
│   ├── Services/
│   │   ├── DockerAPIClient.swift
│   │   └── ConfigurationManager.swift
│   ├── UI/
│   │   ├── MenuBarView.swift
│   │   └── SettingsWindow.swift
│   ├── Utilities/
│   └── Resources/
├── DockerMonitorTests/
└── README.md
```

**9.3 Testing Strategy**
- Unit tests for API client
- Mock Docker API responses
- UI testing approach
- Integration testing with real Docker daemon

### Section 10: Implementation Roadmap

**Phase 1: MVP (Core Functionality)**
Sprint 1 (Week 1-2):
- [ ] Set up Xcode project structure
- [ ] Implement menu bar icon and basic UI
- [ ] Create Docker API client (basic connection)
- [ ] Implement container listing

Sprint 2 (Week 3-4):
- [ ] Add container stats retrieval
- [ ] Implement basic controls (start/stop/restart)
- [ ] Build settings window for Docker host configuration
- [ ] Add auto-refresh functionality

Sprint 3 (Week 5-6):
- [ ] Implement secure credential storage
- [ ] Add container log viewing
- [ ] Polish UI and error handling
- [ ] Testing and bug fixes

**Phase 2: Enhanced Features** (Future)
- Multi-host support
- Image management
- Volume/network management
- Container creation

**Phase 3: Advanced Features** (Future)
- Kubernetes support
- Podman integration
- Alerts and notifications
- Advanced filtering and search

### Section 11: Key Design Decisions

Document all major design decisions and their rationale:

**Decision 1: Swift/macOS Native vs. Electron**
- Rationale: CodexBar uses Swift; native performance and macOS integration
- Trade-offs: Platform-specific but better performance and system integration

**Decision 2: Direct Docker API vs. Docker CLI**
- Rationale: Direct API access provides better control and real-time data
- Trade-offs: More complex but more flexible

**Decision 3: Polling vs. WebSocket/Streaming**
- Rationale: [Design agent should decide based on Docker API capabilities]
- Trade-offs: [Document pros/cons]

[Add more as discovered during design process]

### Section 12: Security Considerations

**12.1 Credential Storage**
- Use macOS Keychain for storing:
  - Docker host passwords
  - TLS certificates and keys
  - SSH private keys

**12.2 Network Security**
- Always use TLS for remote connections
- Validate server certificates
- Support SSH tunneling as secure alternative

**12.3 Permission Model**
- Minimal permissions required
- Sandbox considerations (if applicable)

### Section 13: User Experience Guidelines

**13.1 Interaction Patterns**
- Quick access from menu bar (1 click)
- Container details on hover or secondary click
- Confirmation dialogs for destructive actions (remove container)
- Visual feedback for loading states
- Clear error messages

**13.2 Visual Design**
- Consistent with macOS Big Sur+ design language
- Color coding for container states:
  - Green: Running
  - Red: Stopped
  - Yellow: Paused
  - Orange: Restarting
- Icons for common actions

**13.3 Accessibility**
- VoiceOver support
- Keyboard shortcuts for common actions
- High contrast mode support

### Section 14: Testing & Validation

**14.1 Test Environment**
- Testing with 12 containers on Beelink server
- Various container states (running, stopped, paused)
- Edge cases: container crashes, network issues

**14.2 Test Scenarios**
1. Connect to Docker host successfully
2. Display all 12 containers with correct status
3. Start a stopped container
4. Stop a running container
5. View real-time stats updates
6. Handle connection loss gracefully
7. Reconnect after network restoration
8. Handle Docker daemon restart

**14.3 Performance Benchmarks**
- Menu bar responsiveness (<100ms)
- Stats update latency
- Memory footprint (<50MB)
- CPU usage while idle (<1%)

### Section 15: Documentation Requirements

The implementation agent will need:
- Inline code documentation (comments for complex logic)
- README with setup instructions
- User guide for configuration
- Troubleshooting guide for common issues

---

## Instructions for Design Agent

### Analysis Review Process

**Step 1: Read All Analysis Documents**
Carefully review all markdown files in `new-monitoring-app/`:
- `00-overview.md` through `10-recommendations-for-clone.md`
- Take notes on patterns applicable to Docker monitoring
- Identify gaps that need Docker-specific solutions

**Step 2: Map CodexBar Patterns to Docker Monitor**
Create a mapping table:
| CodexBar Pattern | Applicability | Adaptation Needed |
|------------------|---------------|-------------------|
| Menu bar UI | Direct reuse | Update branding/icons |
| API integration | Adapt | Different API (Docker vs AI tools) |
| State management | Direct reuse | Different data models |
| ... | ... | ... |

**Step 3: Design Docker-Specific Components**
For each component not covered by CodexBar:
- Docker API client architecture
- Container stats streaming
- TLS/SSH connection handling
- Real-time metric updates

**Step 4: Create Comprehensive Design Document**
Write `DESIGN_DOCUMENT.md` with all 15 sections listed above:
- Be specific and detailed
- Include code snippets and examples
- Create diagrams where helpful
- Reference CodexBar analysis where applicable

**Step 5: Validate Completeness**
Ensure the design document answers:
- [ ] What technologies to use (languages, frameworks, libraries)
- [ ] How to structure the codebase
- [ ] What data models are needed
- [ ] How components interact
- [ ] How to handle errors and edge cases
- [ ] How to test the application
- [ ] Step-by-step implementation roadmap
- [ ] All UI/UX specifications

### Quality Standards

The design document must be:
1. **Implementable**: Another agent should be able to code directly from it
2. **Complete**: No major design questions left unanswered
3. **Specific**: Concrete technical decisions, not vague descriptions
4. **Realistic**: Based on proven patterns from CodexBar
5. **Well-structured**: Easy to navigate and reference

### Output Format

- **Single file**: `new-monitoring-app/DESIGN_DOCUMENT.md`
- **Length**: Comprehensive (expect 5,000-10,000 words)
- **Format**: Well-organized Markdown with clear headings
- **Code examples**: Include pseudo-code and Swift snippets where helpful
- **Diagrams**: Use Mermaid or ASCII art for visual representations

---

## Definition of Done

The design document is complete when:

- [ ] All 15 sections are written with substantive content
- [ ] CodexBar patterns are explicitly mapped to Docker monitoring needs
- [ ] All technical decisions are documented with rationale
- [ ] Data models are fully specified
- [ ] API integration approach is clearly defined
- [ ] UI/UX is completely specified (mockups/wireframes included)
- [ ] Implementation roadmap is actionable
- [ ] Security and error handling are addressed
- [ ] Testing strategy is defined
- [ ] Another agent could implement the app using only this document

---

## Example Design Document Snippet

Here's an example of the expected level of detail:

### From Section 6.1 (Docker API Client Design):

```markdown
## Docker API Client Implementation

### Architecture
The Docker API client will be implemented as a separate service layer that abstracts all Docker Engine API interactions. This follows the same pattern used in CodexBar for AI tool integrations (see analysis document `06-api-integrations.md`).

### Swift Implementation

```swift
import Foundation

protocol DockerAPIClient {
    func connect(host: DockerHost) async throws
    func disconnect()
    func listContainers(all: Bool) async throws -> [DockerContainer]
    func getContainerStats(id: String, stream: Bool) async throws -> AsyncStream<ContainerStats>
    func startContainer(id: String) async throws
    func stopContainer(id: String, timeout: Int?) async throws
    func restartContainer(id: String, timeout: Int?) async throws
    func removeContainer(id: String, force: Bool) async throws
    func getContainerLogs(id: String, tail: Int?) async throws -> String
}

class DockerAPIClientImpl: DockerAPIClient {
    private var session: URLSession
    private var baseURL: URL
    private var connectionType: ConnectionType
    
    init(config: DockerClientConfig) {
        // Initialize URLSession with appropriate configuration
        // Handle TLS certificates if provided
        // Set up SSH tunnel if needed
    }
    
    func connect(host: DockerHost) async throws {
        // Implementation:
        // 1. Validate host configuration
        // 2. Establish connection based on type (TLS, SSH, Unix socket)
        // 3. Ping Docker daemon to verify connection
        // 4. Store connection for subsequent requests
        
        let pingURL = baseURL.appendingPathComponent("_ping")
        let (_, response) = try await session.data(from: pingURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DockerAPIError.connectionFailed
        }
    }
    
    func listContainers(all: Bool = false) async throws -> [DockerContainer] {
        // Build URL with query parameters
        var components = URLComponents(url: baseURL.appendingPathComponent("containers/json"), resolvingAgainstBaseURL: true)
        components?.queryItems = [URLQueryItem(name: "all", value: all ? "true" : "false")]
        
        guard let url = components?.url else {
            throw DockerAPIError.invalidURL
        }
        
        // Make request
        let (data, _) = try await session.data(from: url)
        
        // Parse response
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([DockerContainer].self, from: data)
    }
    
    // ... additional method implementations
}
```

### Error Handling
All API methods throw typed errors for better error handling:

```swift
enum DockerAPIError: Error, LocalizedError {
    case connectionFailed
    case unauthorized
    case notFound(String)
    case serverError(String)
    case networkTimeout
    case invalidResponse
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Failed to connect to Docker daemon"
        case .unauthorized:
            return "Unauthorized: Check your credentials"
        case .notFound(let resource):
            return "\(resource) not found"
        case .serverError(let message):
            return "Docker daemon error: \(message)"
        case .networkTimeout:
            return "Connection timed out"
        case .invalidResponse:
            return "Invalid response from Docker daemon"
        case .invalidURL:
            return "Invalid Docker host URL"
        }
    }
}
```

### Connection Types
Support three connection types:

1. **Unix Socket** (local Docker daemon)
   ```swift
   let config = DockerClientConfig(
       connectionType: .unixSocket,
       socketPath: "/var/run/docker.sock"
   )
   ```

2. **TCP with TLS** (remote Docker daemon with certificates)
   ```swift
   let config = DockerClientConfig(
       connectionType: .tcpTLS,
       host: "192.168.1.100",
       port: 2376,
       tlsCert: certData,
       tlsKey: keyData,
       tlsCA: caData
   )
   ```

3. **SSH Tunnel** (secure connection via SSH)
   ```swift
   let config = DockerClientConfig(
       connectionType: .ssh,
       sshHost: "192.168.1.100",
       sshUser: "user",
       sshKey: privateKeyData,
       remoteSocketPath: "/var/run/docker.sock"
   )
   ```

### Rate Limiting & Throttling
The Docker API doesn't impose rate limits, but we should implement client-side throttling to avoid overwhelming the daemon:

- Maximum 10 concurrent requests
- Debounce rapid refresh requests (minimum 1 second between refreshes)
- Use connection pooling for better performance

### Streaming Stats
For real-time container statistics, use the streaming stats endpoint:

```swift
func getContainerStats(id: String, stream: Bool = true) async throws -> AsyncStream<ContainerStats> {
    let url = baseURL.appendingPathComponent("containers/\(id)/stats")
        .appending(queryItems: [URLQueryItem(name: "stream", value: stream ? "true" : "false")])
    
    return AsyncStream { continuation in
        Task {
            do {
                let (bytes, response) = try await session.bytes(from: url)
                
                for try await line in bytes.lines {
                    if let data = line.data(using: .utf8) {
                        let stats = try JSONDecoder().decode(ContainerStats.self, from: data)
                        continuation.yield(stats)
                    }
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}
```

This design allows consuming stats as an async stream:
```swift
for await stats in try await client.getContainerStats(id: containerId) {
    // Update UI with latest stats
    updateUI(with: stats)
}
```
```

---

## Begin Design Process

Read all analysis documents in the `new-monitoring-app/` folder and create the comprehensive design document as specified above. Work systematically through each section, ensuring completeness and technical accuracy.

The success of the implementation agent depends on the quality and completeness of this design document. Take your time and be thorough.