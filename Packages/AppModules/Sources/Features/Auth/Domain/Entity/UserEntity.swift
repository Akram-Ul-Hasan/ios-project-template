import Foundation

/// The signed-in user. Data only (rule 1).
public struct UserEntity: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let phone: String
    /// `nil` = the user hasn't added an email.
    public let email: String?
    /// `nil` = no profile photo; the UI shows initials.
    public let avatarURL: URL?

    public init(id: String, name: String, phone: String, email: String?, avatarURL: URL?) {
        self.id = id
        self.name = name
        self.phone = phone
        self.email = email
        self.avatarURL = avatarURL
    }
}
