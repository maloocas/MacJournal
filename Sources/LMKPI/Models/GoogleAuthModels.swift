import Foundation

// MARK: - Google SDK Configuration

/// Loaded from ~/.lmkpi/google_credentials.json (downloaded from Google Cloud Console).
/// This file contains the OAuth 2.0 client ID and secret for a Desktop Application.
struct GoogleSDKConfig: Codable {
    struct Installed: Codable {
        let clientId: String
        let clientSecret: String
        let projectId: String?
        let authUri: String?
        let tokenUri: String?

        enum CodingKeys: String, CodingKey {
            case clientId = "client_id"
            case clientSecret = "client_secret"
            case projectId = "project_id"
            case authUri = "auth_uri"
            case tokenUri = "token_uri"
        }
    }
    let installed: Installed

    var clientId: String { installed.clientId }
    var clientSecret: String { installed.clientSecret }
    var tokenUri: String { installed.tokenUri ?? "https://oauth2.googleapis.com/token" }
    var authUri: String { installed.authUri ?? "https://accounts.google.com/o/oauth2/auth" }
}

// MARK: - OAuth Token Responses

/// Response from POST /token with grant_type=authorization_code
struct GoogleTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let scope: String
    let tokenType: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case scope = "scope"
        case tokenType = "token_type"
    }
}

/// Error from Google's token endpoint
struct GoogleTokenError: Codable, Error, LocalizedError {
    let error: String
    let errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
    }

    var errorDescriptionFull: String? {
        errorDescription ?? error
    }
}

// MARK: - Credentials Stored in Keychain

/// Persisted in the macOS Keychain between app launches.
/// The access_token is kept in-memory only; the refresh_token lives here.
struct StoredCredentials: Codable {
    let refreshToken: String
    var scopes: [String]         // e.g. ["https://www.googleapis.com/auth/calendar.readonly"]
    var userEmail: String?
    var userName: String?
}

// MARK: - User Info

/// Response from GET https://www.googleapis.com/oauth2/v3/userinfo
struct GoogleUserInfo: Codable {
    let email: String
    let name: String?
    let picture: String?
}

// MARK: - Scope Constants

/// Named scopes for Google Workspace services.
/// Add new scopes here when adding new services.
enum GoogleScope: String, CaseIterable {
    case calendarReadonly = "https://www.googleapis.com/auth/calendar.readonly"
    case userinfoEmail   = "https://www.googleapis.com/auth/userinfo.email"
    case userinfoProfile = "https://www.googleapis.com/auth/userinfo.profile"

    // Future scopes (uncomment when implementing):
    // case mailReadonly = "https://www.googleapis.com/auth/gmail.readonly"
    // case driveReadonly = "https://www.googleapis.com/auth/drive.readonly"
    // case tasksReadonly = "https://www.googleapis.com/auth/tasks.readonly"

    /// Base scopes required for every session (gets user email / name).
    static let base: [GoogleScope] = [.userinfoEmail, .userinfoProfile]

    /// All scopes currently in use across enabled services.
    /// Computed from the active registry at runtime.
    static var allStringValues: [String] {
        base.map(\.rawValue)
    }
}
