import Localization
import SharedDomain

// Every error case has a localized message. The switches are exhaustive on purpose:
// a new case doesn't compile until it has an `L10n` message (rule 36).

extension ResponseError {
    public var localizedMessage: String {
        switch self {
        case .network: L10n.Error.network
        case .timeout: L10n.Error.timeout
        case .unauthorized: L10n.Error.unauthorized
        case .forbidden: L10n.Error.forbidden
        case .notFound: L10n.Error.notFound
        case .validation(let message, _): message.nonEmpty ?? L10n.Error.validation
        // A server message is already localized (Accept-Language), so it wins over the generic text.
        case .business(let code, let message): message.nonEmpty ?? code?.localizedMessage ?? L10n.Error.generic
        case .server: L10n.Error.server
        case .maintenance: L10n.Error.maintenance
        case .updateRequired: L10n.Error.updateRequired
        case .domain(let error): error.localizedMessage
        case .invalidResponse, .cancelled, .unknown: L10n.Error.generic
        }
    }
}

extension BackendErrorCode {
    public var localizedMessage: String {
        switch self {
        case .outOfStock: L10n.Error.outOfStock
        case .couponExpired: L10n.Error.couponExpired
        case .unknown: L10n.Error.generic
        }
    }
}

extension DomainError {
    public var localizedMessage: String {
        switch self {
        case .validation(_, let error): error.localizedMessage
        case .outOfStock: L10n.Error.outOfStock
        case .subscriptionRequired: L10n.Error.subscriptionRequired
        }
    }
}

extension ValidationError {
    public var localizedMessage: String {
        switch self {
        case .required: L10n.Validation.required
        case .tooShort(let min): L10n.Validation.tooShort(min)
        case .tooLong(let max): L10n.Validation.tooLong(max)
        case .invalidFormat(.phone): L10n.Validation.phone
        case .invalidFormat(.email): L10n.Validation.email
        case .invalidFormat(.otp): L10n.Validation.otp(ValidationConstants.otpLength)
        case .invalidFormat(.password): L10n.Validation.password
        case .mismatch: L10n.Validation.mismatch
        case .outOfRange: L10n.Validation.outOfRange
        }
    }
}

extension Optional where Wrapped == String {
    fileprivate var nonEmpty: String? {
        guard let self, !self.isEmpty else { return nil }
        return self
    }
}
