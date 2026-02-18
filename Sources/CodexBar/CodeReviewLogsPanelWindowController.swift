import AppKit
import CodexBarCore
import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
private final class CodeReviewLogsPanelModel {
    var entries: [OpenAICodeReviewLogEntry] = []
}

@MainActor
final class CodeReviewLogsPanelWindowController: NSWindowController {
    private static let defaultSize = NSSize(width: 760, height: 520)
    private let model = CodeReviewLogsPanelModel()
    private var hasCenteredWindow = false

    init() {
        let rootView = CodeReviewLogsPanelView(model: self.model, onOpenURL: Self.openLogURL)
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Code Review Logs"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.minSize = NSSize(width: 620, height: 360)
        window.setContentSize(Self.defaultSize)
        window.isReleasedWhenClosed = false
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(entries: [OpenAICodeReviewLogEntry]) {
        self.model.entries = entries
        guard let window = self.window else { return }
        if !self.hasCenteredWindow {
            window.center()
            self.hasCenteredWindow = true
        }
        self.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private nonisolated static func openLogURL(_ rawURL: String?) {
        guard let url = self.sanitizedLogURL(rawURL) else { return }
        DispatchQueue.main.async {
            NSWorkspace.shared.open(url)
        }
    }

    private nonisolated static func sanitizedLogURL(_ rawURL: String?) -> URL? {
        guard let rawURL else { return nil }
        let trimmed = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let absoluteURL = URL(string: trimmed),
           let scheme = absoluteURL.scheme?.lowercased(),
           scheme == "http" || scheme == "https",
           let host = absoluteURL.host?.lowercased(),
           host.contains("chatgpt.com")
        {
            return absoluteURL
        }
        guard let baseURL = URL(string: "https://chatgpt.com"),
              let resolved = URL(string: trimmed, relativeTo: baseURL)?.absoluteURL,
              let host = resolved.host?.lowercased(),
              host.contains("chatgpt.com") else { return nil }
        return resolved
    }
}

private struct CodeReviewLogsPanelView: View {
    @Bindable var model: CodeReviewLogsPanelModel
    let onOpenURL: (String?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Code Reviews")
                    .font(.title3.weight(.semibold))
                Spacer()
                Text("\(self.model.entries.count) total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if self.displayedEntries.isEmpty {
                Text("No code review logs found yet.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(self.displayedEntries) { entry in
                            CodeReviewLogRowView(entry: entry, onOpenURL: self.onOpenURL)
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(minWidth: 640, minHeight: 400, alignment: .topLeading)
    }

    private var displayedEntries: [OpenAICodeReviewLogEntry] {
        Array(self.model.entries.prefix(200))
    }
}

private struct CodeReviewLogRowView: View {
    private static let dateRegex = try? NSRegularExpression(
        pattern: "\\b(?:today|yesterday|(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\s+\\d{1,2})\\b",
        options: .caseInsensitive)
    private static let bugRegex = try? NSRegularExpression(
        pattern: "\\b(\\d+)\\s+bugs?\\b",
        options: .caseInsensitive)
    private static let knownStates = ["Merged", "Closed", "Pending", "In review"]

    struct Metadata {
        let dateText: String?
        let bugCount: Int?
        let stateText: String?
        let actionText: String?
    }

    let entry: OpenAICodeReviewLogEntry
    let onOpenURL: (String?) -> Void

    var body: some View {
        let metadata = self.resolvedMetadata(for: self.entry)
        VStack(alignment: .leading, spacing: 6) {
            Text(self.entry.title)
                .font(.headline)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let subtitle = self.entry.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 8) {
                if let dateText = metadata.dateText {
                    self.pill(text: dateText, style: .neutral)
                }
                if let bugCount = metadata.bugCount {
                    let label = bugCount == 1 ? "1 bug" : "\(bugCount) bugs"
                    self.pill(text: label, style: .warning)
                }
                if let stateText = metadata.stateText {
                    self.pill(text: stateText, style: self.stateStyle(for: stateText))
                }
                if let actionText = metadata.actionText, self.entry.url != nil {
                    Button(action: { self.onOpenURL(self.entry.url) }, label: {
                        self.pill(text: actionText, style: .action)
                    })
                    .buttonStyle(.plain)
                } else if self.entry.url != nil {
                    Button(action: { self.onOpenURL(self.entry.url) }, label: {
                        self.pill(text: "Open", style: .action)
                    })
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private enum PillStyle {
        case neutral
        case warning
        case success
        case error
        case action
    }

    private func stateStyle(for state: String) -> PillStyle {
        switch state.lowercased() {
        case "merged":
            .success
        case "closed":
            .error
        default:
            .neutral
        }
    }

    @ViewBuilder
    private func pill(text: String, style: PillStyle) -> some View {
        let colors = self.colors(for: style)
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(colors.foreground)
            .background(
                Capsule(style: .continuous)
                    .fill(colors.background))
    }

    private func colors(for style: PillStyle) -> (foreground: Color, background: Color) {
        switch style {
        case .neutral:
            (Color.secondary, Color(nsColor: .quaternaryLabelColor).opacity(0.25))
        case .warning:
            (Color(nsColor: .systemOrange), Color(nsColor: .systemOrange).opacity(0.16))
        case .success:
            (Color(nsColor: .systemPurple), Color(nsColor: .systemPurple).opacity(0.16))
        case .error:
            (Color(nsColor: .systemRed), Color(nsColor: .systemRed).opacity(0.16))
        case .action:
            (Color.primary, Color(nsColor: .controlAccentColor).opacity(0.18))
        }
    }

    private func resolvedMetadata(for entry: OpenAICodeReviewLogEntry) -> Metadata {
        var dateText = self.sanitizedText(entry.dateText)
        var bugCount = entry.bugCount
        var stateText = self.sanitizedText(entry.stateText)
        var actionText = self.sanitizedText(entry.actionText)
        let source = self.sanitizedText(entry.subtitle) ?? ""

        if dateText == nil {
            dateText = Self.firstMatch(in: source, regex: Self.dateRegex)
        }
        if bugCount == nil,
           let rawBug = Self.captureGroup(in: source, regex: Self.bugRegex, index: 1)
        {
            bugCount = Int(rawBug)
        }
        if stateText == nil {
            stateText = Self.knownStates.first { source.localizedCaseInsensitiveContains($0) }
        }
        if stateText?.localizedCaseInsensitiveCompare("Open") == .orderedSame {
            stateText = nil
        }
        if actionText == nil {
            if source.localizedCaseInsensitiveContains("fix") {
                actionText = "Fix"
            } else if source.localizedCaseInsensitiveContains("open") {
                actionText = "Open"
            }
        }
        return Metadata(dateText: dateText, bugCount: bugCount, stateText: stateText, actionText: actionText)
    }

    private func sanitizedText(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func firstMatch(in source: String, regex: NSRegularExpression?) -> String? {
        guard !source.isEmpty, let regex else { return nil }
        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        guard let match = regex.firstMatch(in: source, options: [], range: range),
              let valueRange = Range(match.range, in: source) else { return nil }
        return String(source[valueRange])
    }

    private static func captureGroup(in source: String, regex: NSRegularExpression?, index: Int) -> String? {
        guard !source.isEmpty, let regex else { return nil }
        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        guard let match = regex.firstMatch(in: source, options: [], range: range),
              match.numberOfRanges > index,
              let valueRange = Range(match.range(at: index), in: source) else { return nil }
        return String(source[valueRange])
    }
}
