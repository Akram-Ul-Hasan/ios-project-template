import Core
import SwiftUI

/// Renders a screen's `ViewState` so no screen hand-writes the switch (rule 14, §6f):
/// ```
/// ViewStateContainer(state: viewModel.state, onRetry: { await viewModel.load() },
///                    onRefresh: { await viewModel.refresh() }) { data in HomeContent(data: data) }
/// ```
/// - `.idle` / `.loading`: `LoadingView`, or the skeleton passed as `loading`.
/// - `.failure`: `EmptyStateView(error:)` with Retry; a network failure retries by itself when the connection returns.
/// - `.success` where `isEmpty` is true: the empty state.
/// Refresh keeps the content on screen; the view model reports refresh failures as a snackbar (§6m).
public struct ViewStateContainer<Value, Content: View, Loading: View>: View {
    private let state: ViewState<Value>
    private let isEmpty: (Value) -> Bool
    private let emptyState: EmptyStateView
    private let onRetry: (@MainActor () async -> Void)?
    private let onRefresh: (@MainActor () async -> Void)?
    private let loading: Loading
    private let content: (Value) -> Content

    @Environment(NetworkMonitor.self) private var network: NetworkMonitor?

    public init(
        state: ViewState<Value>,
        isEmpty: @escaping (Value) -> Bool = { _ in false },
        emptyState: EmptyStateView = EmptyStateView(),
        onRetry: (@MainActor () async -> Void)?,
        onRefresh: (@MainActor () async -> Void)? = nil,
        @ViewBuilder loading: () -> Loading,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.state = state
        self.isEmpty = isEmpty
        self.emptyState = emptyState
        self.onRetry = onRetry
        self.onRefresh = onRefresh
        self.loading = loading()
        self.content = content
    }

    public var body: some View {
        Group {
            switch state {
            case .idle, .loading:
                loading
            case .failure(let error):
                centered(EmptyStateView(error: error, retry: onRetry.map { retry in { Task { await retry() } } }))
            case .success(let value):
                if isEmpty(value) {
                    centered(emptyState)
                } else {
                    content(value)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .refreshable(action: onRefresh)
        .onChange(of: network?.isOnline) { wasOnline, isOnline in
            guard wasOnline == false, isOnline == true, state.error == .network, let onRetry else { return }
            Task { await onRetry() }
        }
    }

    /// Scrollable so pull to refresh also works on empty and error states.
    private func centered(_ view: EmptyStateView) -> some View {
        ScrollView {
            view.containerRelativeFrame([.horizontal, .vertical])
        }
    }
}

extension ViewStateContainer where Loading == LoadingView {
    public init(
        state: ViewState<Value>,
        isEmpty: @escaping (Value) -> Bool = { _ in false },
        emptyState: EmptyStateView = EmptyStateView(),
        onRetry: (@MainActor () async -> Void)?,
        onRefresh: (@MainActor () async -> Void)? = nil,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.init(
            state: state, isEmpty: isEmpty, emptyState: emptyState, onRetry: onRetry, onRefresh: onRefresh,
            loading: { LoadingView() }, content: content)
    }
}

extension View {
    /// `.refreshable` only when there is something to refresh.
    @ViewBuilder
    fileprivate func refreshable(action: (@MainActor () async -> Void)?) -> some View {
        if let action {
            refreshable { await action() }
        } else {
            self
        }
    }
}

#Preview("States") {
    TabView {
        ViewStateContainer(state: ViewState<[String]>.loading, onRetry: {}) { _ in EmptyView() }
            .tabItem { Text(verbatim: "Loading") }
        ViewStateContainer(state: ViewState<[String]>.failure(.network), onRetry: {}) { _ in EmptyView() }
            .tabItem { Text(verbatim: "Offline") }
        ViewStateContainer(state: ViewState<[String]>.success([]), isEmpty: \.isEmpty, onRetry: {}) { _ in EmptyView() }
            .tabItem { Text(verbatim: "Empty") }
        ViewStateContainer(state: ViewState<[String]>.success(["Rice", "Dal"]), onRetry: {}) { items in
            List(items, id: \.self) { Text($0) }
        }
        .tabItem { Text(verbatim: "Content") }
    }
}
