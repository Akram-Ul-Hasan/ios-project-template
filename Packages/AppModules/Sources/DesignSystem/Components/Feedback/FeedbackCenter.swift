import Core
import Foundation
import Observation
import SwiftUI

/// Shows toasts and snackbars one at a time (§6m). Implements Core's `FeedbackPresenting`, so view models
/// call `feedback.show(.success(…))` without knowing about UI. Created once in `AppContainer`.
@MainActor
@Observable
public final class FeedbackCenter: FeedbackPresenting {
    /// The message on screen, if any.
    public private(set) var current: FeedbackMessage?
    /// Changes with every new message: drives transitions and haptics.
    public private(set) var currentID = UUID()

    @ObservationIgnored private var queue: [FeedbackMessage] = []
    @ObservationIgnored private var dismissTask: Task<Void, Never>?
    @ObservationIgnored private let announce: @MainActor (String) -> Void

    /// `announce` reads each message to VoiceOver users; tests pass a recorder.
    public init(announce: @escaping @MainActor (String) -> Void = { AccessibilityNotification.Announcement($0).post() })
    {
        self.announce = announce
    }

    public func show(_ message: FeedbackMessage) {
        // The same message twice in a row (double tap, two failing requests) shows once.
        guard message != current, !queue.contains(message) else { return }
        queue.append(message)
        advance()
    }

    public func dismiss() {
        dismissTask?.cancel()
        current = nil
        advance()
    }

    /// Runs the snackbar's action ("Undo", "Retry") and dismisses it.
    public func performAction() {
        let action = current?.action
        dismiss()
        action?.handler()
    }

    private func advance() {
        guard current == nil, !queue.isEmpty else { return }
        let next = queue.removeFirst()
        current = next
        currentID = UUID()
        announce(next.text)
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: next.duration)
            guard !Task.isCancelled else { return }
            self?.dismiss()
        }
    }
}
