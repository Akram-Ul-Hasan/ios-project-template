/// What a screen shows. Rendered by `ViewStateContainer`, so no screen hand-writes this switch (rule 14).
public enum ViewState<Value> {
    case idle
    case loading
    case success(Value)
    case failure(ResponseError)

    public var value: Value? {
        guard case .success(let value) = self else { return nil }
        return value
    }

    public var error: ResponseError? {
        guard case .failure(let error) = self else { return nil }
        return error
    }

    public var isLoading: Bool {
        guard case .loading = self else { return false }
        return true
    }
}

extension ViewState: Equatable where Value: Equatable {}
extension ViewState: Sendable where Value: Sendable {}
