import SwiftUI

extension View {
    /// `.refreshable` only when there is something to refresh.
    @ViewBuilder
    func refreshable(action: (@MainActor () async -> Void)?) -> some View {
        if let action {
            refreshable { await action() }
        } else {
            self
        }
    }
}
