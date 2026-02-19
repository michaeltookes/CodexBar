import Testing
@testable import CodexBar

@Suite
struct CodeReviewLogsPanelWindowControllerTests {
    @Test
    func acceptsChatGPTCodeReviewURL() {
        let url = CodeReviewLogsPanelWindowController
            .sanitizedLogURL("https://chatgpt.com/codex?tab=code_reviews")
        #expect(url?.absoluteString == "https://chatgpt.com/codex?tab=code_reviews")
    }

    @Test
    func resolvesRelativeChatGPTCodeReviewURL() {
        let url = CodeReviewLogsPanelWindowController.sanitizedLogURL("/codex?tab=code_reviews")
        #expect(url?.absoluteString == "https://chatgpt.com/codex?tab=code_reviews")
    }

    @Test
    func acceptsChatGPTSubdomainCodeReviewURL() {
        let url = CodeReviewLogsPanelWindowController
            .sanitizedLogURL("https://platform.chatgpt.com/codex?tab=code_reviews")
        #expect(url?.absoluteString == "https://platform.chatgpt.com/codex?tab=code_reviews")
    }

    @Test
    func acceptsGitHubReviewURLs() {
        let url = CodeReviewLogsPanelWindowController
            .sanitizedLogURL("https://github.com/org/repo/pull/123")
        #expect(url?.absoluteString == "https://github.com/org/repo/pull/123")
    }

    @Test
    func rejectsNonReviewGitHubURLs() {
        let url = CodeReviewLogsPanelWindowController.sanitizedLogURL("https://github.com/org/repo")
        #expect(url == nil)
    }

    @Test
    func rejectsUnsupportedSchemesAndHosts() {
        let javascriptURL = CodeReviewLogsPanelWindowController.sanitizedLogURL("javascript:alert(1)")
        let externalURL = CodeReviewLogsPanelWindowController.sanitizedLogURL("https://example.com/review/1")
        let spoofedChatGPTURL = CodeReviewLogsPanelWindowController.sanitizedLogURL("https://evil-chatgpt.com/codex")
        #expect(javascriptURL == nil)
        #expect(externalURL == nil)
        #expect(spoofedChatGPTURL == nil)
    }
}
