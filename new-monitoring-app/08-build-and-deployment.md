# Build and Deployment

## Overview

CodexBar uses a **SwiftPM-only** build system (no Xcode project). The build process involves:
1. Swift Package Manager compilation
2. App bundle assembly via shell scripts
3. Code signing with Developer ID
4. Apple notarization
5. Sparkle appcast generation for auto-updates

## Build System

### Swift Package Manager

**Package.swift** defines multiple targets:

```swift
let package = Package(
    name: "CodexBar",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "CodexBar", targets: ["CodexBar"]),
        .executable(name: "CodexBarCLI", targets: ["CodexBarCLI"]),
        .library(name: "CodexBarCore", targets: ["CodexBarCore"]),
    ],
    // ...
)
```

### Version Configuration

**version.env** (sourced by all scripts):
```bash
MARKETING_VERSION=0.17.0
BUILD_NUMBER=48
```

### Build Commands

**Development build**:
```bash
# Single architecture (host arch)
swift build

# Debug configuration
swift build -c debug

# Release configuration
swift build -c release
```

**Universal build** (arm64 + x86_64):
```bash
swift build -c release --arch arm64
swift build -c release --arch x86_64
```

## Build Scripts

### Scripts Overview

| Script | Purpose |
|--------|---------|
| `compile_and_run.sh` | Development: build + run |
| `package_app.sh` | Create .app bundle from build artifacts |
| `sign-and-notarize.sh` | Sign, notarize, staple |
| `make_appcast.sh` | Generate Sparkle appcast.xml |
| `release.sh` | Full automated release |

### compile_and_run.sh

**Purpose**: Quick development iteration.

```bash
#!/usr/bin/env bash
./Scripts/compile_and_run.sh [debug|release]

# What it does:
# 1. Build for host architecture
# 2. Patch KeyboardShortcuts resource bundle issue
# 3. Create .app bundle via package_app.sh
# 4. Sign (ad-hoc for debug)
# 5. Launch app
```

### package_app.sh (380 lines)

**Purpose**: Assemble complete .app bundle from build artifacts.

**Key operations**:
1. Create app directory structure
2. Copy compiled binaries (lipo for universal)
3. Generate Info.plist with version/build info
4. Embed Sparkle.framework
5. Copy resources (icons, localization bundles)
6. Sign nested components
7. Sign main app bundle

**Directory structure created**:
```
CodexBar.app/
├── Contents/
│   ├── Info.plist           # Generated
│   ├── MacOS/
│   │   └── CodexBar         # Main binary
│   ├── Helpers/
│   │   ├── CodexBarCLI      # CLI binary
│   │   └── CodexBarClaudeWatchdog
│   ├── Frameworks/
│   │   └── Sparkle.framework/
│   ├── PlugIns/
│   │   └── CodexBarWidget.appex/
│   └── Resources/
│       ├── Icon.icns
│       ├── ProviderIcon-*.svg
│       └── KeyboardShortcuts_KeyboardShortcuts.bundle/
```

### sign-and-notarize.sh

**Purpose**: Production signing and Apple notarization.

**Prerequisites**:
- Developer ID certificate installed
- App Store Connect API credentials
- Sparkle private key

```bash
# Required environment variables
APP_STORE_CONNECT_API_KEY_P8="..."
APP_STORE_CONNECT_KEY_ID="..."
APP_STORE_CONNECT_ISSUER_ID="..."
SPARKLE_PRIVATE_KEY_FILE="/path/to/key"
```

**Signing flow**:
```bash
# 1. Build universal binary
swift build -c release --arch arm64
swift build -c release --arch x86_64

# 2. Package app
./Scripts/package_app.sh release

# 3. Sign helpers
codesign --force --timestamp --options runtime --sign "$APP_IDENTITY" \
  CodexBar.app/Contents/Helpers/CodexBarCLI

# 4. Sign widget
codesign --force --timestamp --options runtime --sign "$APP_IDENTITY" \
  --entitlements $WIDGET_ENTITLEMENTS \
  CodexBar.app/Contents/PlugIns/CodexBarWidget.appex

# 5. Sign main app
codesign --force --timestamp --options runtime --sign "$APP_IDENTITY" \
  --entitlements $APP_ENTITLEMENTS \
  CodexBar.app

# 6. Submit for notarization
xcrun notarytool submit CodexBar.zip \
  --key api-key.p8 \
  --key-id $KEY_ID \
  --issuer $ISSUER_ID \
  --wait

# 7. Staple notarization ticket
xcrun stapler staple CodexBar.app

# 8. Create final zip
ditto -c -k --keepParent CodexBar.app CodexBar-0.17.0.zip
```

### Entitlements

**App entitlements** (`.build/entitlements/CodexBar.entitlements`):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.steipete.codexbar</string>
    </array>
</dict>
</plist>
```

**Widget entitlements**:
```xml
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.steipete.codexbar</string>
    </array>
</dict>
```

## Auto-Update (Sparkle)

### Configuration

**Info.plist keys**:
```xml
<key>SUFeedURL</key>
<string>https://raw.githubusercontent.com/steipete/CodexBar/main/appcast.xml</string>
<key>SUPublicEDKey</key>
<string>AGCY8w5vHirVfGGDGc8Szc5iuOqupZSh9pMj/Qs67XI=</string>
<key>SUEnableAutomaticChecks</key>
<true/>
```

### Appcast Generation

```bash
./Scripts/make_appcast.sh CodexBar-0.17.0.zip \
  https://raw.githubusercontent.com/steipete/CodexBar/main/appcast.xml

# Requires SPARKLE_PRIVATE_KEY_FILE
# Generates HTML release notes from CHANGELOG.md
```

**appcast.xml format**:
```xml
<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <item>
      <title>0.17.0</title>
      <pubDate>Thu, 04 Dec 2025 18:00:00 +0000</pubDate>
      <sparkle:version>48</sparkle:version>
      <sparkle:shortVersionString>0.17.0</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <enclosure
        url="https://github.com/.../releases/download/v0.17.0/CodexBar-0.17.0.zip"
        sparkle:edSignature="..."
        length="..."
        type="application/octet-stream"/>
      <description><![CDATA[<ul><li>...</li></ul>]]></description>
    </item>
  </channel>
</rss>
```

## Distribution Channels

### 1. GitHub Releases (Primary)

**Direct download**:
- Universal `.zip` attached to GitHub release
- Includes dSYM archive for crash symbolication

### 2. Homebrew Cask

**homebrew-tap/Casks/codexbar.rb**:
```ruby
cask "codexbar" do
  version "0.17.0"
  sha256 "..."

  url "https://github.com/steipete/CodexBar/releases/download/v#{version}/CodexBar-#{version}.zip"
  name "CodexBar"
  homepage "https://github.com/steipete/CodexBar"

  app "CodexBar.app"

  # Disable Sparkle when installed via Homebrew
  postflight do
    # ...
  end
end
```

**Installation**:
```bash
brew tap steipete/tap
brew install --cask steipete/tap/codexbar
```

### 3. Build from Source

```bash
git clone https://github.com/steipete/CodexBar.git
cd CodexBar
./Scripts/compile_and_run.sh release
# CodexBar.app is now in the repo root
```

## CI/CD Pipeline

### GitHub Actions (if configured)

**Typical workflow**:
```yaml
jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: swift build -c release
      - name: Test
        run: swift test
      - name: Package
        run: ./Scripts/package_app.sh release
```

### Release Automation

**Scripts/release.sh**:
```bash
# Full release automation
# 1. Validate changelog
# 2. Build + sign + notarize
# 3. Generate appcast
# 4. Create GitHub release
# 5. Upload assets
# 6. Update Homebrew tap
```

## Testing

### Unit Tests

```bash
# Run all tests
swift test

# Run specific test
swift test --filter "CodexBarTests.SnapshotParsingTests"
```

### Test Targets

- `CodexBarTests`: macOS unit tests
- `TestsLinux`: Linux-compatible subset

### Manual Testing Checklist

1. Fresh install from GitHub release
2. Signature verification: `spctl -a -t exec -vv CodexBar.app`
3. Sparkle update from previous version
4. All provider logins work
5. Widget displays correctly

## Development Setup

### Prerequisites

```bash
# Required
xcode-select --install  # Xcode Command Line Tools
brew install swiftformat swiftlint

# For releases
brew install sparkle    # For sign_update, generate_appcast
```

### Development Signing

```bash
# Ad-hoc signing for development
./Scripts/compile_and_run.sh debug

# Or with LLDB support
CODEXBAR_ALLOW_LLDB=1 ./Scripts/compile_and_run.sh debug
```

### Code Quality

```bash
# Format code
swiftformat .

# Lint
swiftlint

# Fix lint issues
swiftlint --fix
```

## Deployment Checklist

1. **Version bump**: Update `version.env`
2. **Changelog**: Update `CHANGELOG.md`
3. **Build**: `./Scripts/sign-and-notarize.sh`
4. **Appcast**: `./Scripts/make_appcast.sh`
5. **GitHub Release**: Create release, upload assets
6. **Homebrew**: Update tap cask
7. **Verify**: Download, install, test update

---

**Summary**: CodexBar's build system is script-based using SwiftPM, enabling reproducible builds without Xcode projects. The signing/notarization pipeline is fully automated. For a container monitoring clone, the same build infrastructure applies with minor customization (different bundle IDs, signing identities).
