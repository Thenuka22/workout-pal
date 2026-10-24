enum AccountProvider: String, Sendable {
    case google
    case offline
}

struct AccountUser: Hashable, Sendable {
    let id: String
    var displayName: String
    var email: String?
    var provider: AccountProvider

    static let offline = AccountUser(id: LocalProfile.ownerID, displayName: "", email: nil, provider: .offline)

    var summary: String {
        switch provider {
        case .google:
            if let email, !email.isEmpty {
                return "Signed in with Google as \(email)"
            }
            return "Signed in with Google"
        case .offline:
            return "Using Workout Pal offline on this device"
        }
    }
}
