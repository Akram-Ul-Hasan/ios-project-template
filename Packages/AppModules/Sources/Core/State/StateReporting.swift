/// The BlocObserver equivalent: in DEBUG, every view model state change is logged to `AppLogger.ui`.
/// Call it from the state's `didSet`: `var state: ViewState<User> = .idle { didSet { transition(to: state) } }`.
public protocol StateReporting: AnyObject {}

extension StateReporting {
    public func transition<State>(to state: State) {
        #if DEBUG
            let name = String(describing: Self.self)
            let description = String(describing: state)
            AppLogger.ui.debug("\(name, privacy: .public) → \(description, privacy: .private)")
        #endif
    }
}
