import SwiftUI

/// Runs an async action and shows a spinner until it finishes; taps are ignored meanwhile,
/// so a slow request can't be submitted twice: `LoadingButton(L10n.Login.submit) { await viewModel.submit() }`.
public struct LoadingButton: View {
    private let title: String
    private let kind: AppButtonStyle.Kind
    private let action: @MainActor () async -> Void
    @State private var isRunning = false

    public init(_ title: String, kind: AppButtonStyle.Kind = .primary, action: @escaping @MainActor () async -> Void) {
        self.title = title
        self.kind = kind
        self.action = action
    }

    public var body: some View {
        AppButton(title, systemImage: nil, kind: kind, size: .regular, isLoading: isRunning) {
            guard !isRunning else { return }
            isRunning = true
            Task {
                await action()
                isRunning = false
            }
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.s12) {
        LoadingButton("Pay now") { try? await Task.sleep(for: .seconds(2)) }
        LoadingButton("Delete account", kind: .destructive) { try? await Task.sleep(for: .seconds(2)) }
    }
    .padding(AppSpacing.s16)
}
