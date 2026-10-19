import Core
import Testing

@testable import DesignSystem

@Suite("FeedbackCenter")
@MainActor
struct FeedbackCenterTests {
    private func message(_ text: String, ms: Int = 30, action: FeedbackAction? = nil) -> FeedbackMessage {
        FeedbackMessage(style: .snackbar, kind: .info, text: text, action: action, duration: .milliseconds(ms))
    }

    @Test("Shows one message at a time, in order, and auto-dismisses")
    func queue() async throws {
        var spoken: [String] = []
        let center = FeedbackCenter { spoken.append($0) }
        center.show(message("one"))
        center.show(message("two"))
        #expect(center.current?.text == "one")
        try await Task.sleep(for: .milliseconds(60))
        #expect(center.current?.text == "two")
        try await Task.sleep(for: .milliseconds(60))
        #expect(center.current == nil)
        #expect(spoken == ["one", "two"])
    }

    @Test("Identical messages are shown once")
    func dedupe() {
        let center = FeedbackCenter { _ in }
        center.show(message("Saved", ms: 1_000))
        center.show(message("Saved", ms: 1_000))
        center.show(message("Other", ms: 1_000))
        center.show(message("Other", ms: 1_000))
        center.dismiss()
        #expect(center.current?.text == "Other")
        center.dismiss()
        #expect(center.current == nil)
    }

    @Test("performAction runs the action and moves on")
    func action() {
        var undone = false
        let center = FeedbackCenter { _ in }
        center.show(message("Removed", ms: 1_000, action: FeedbackAction(title: "Undo") { undone = true }))
        center.performAction()
        #expect(undone)
        #expect(center.current == nil)
    }
}
