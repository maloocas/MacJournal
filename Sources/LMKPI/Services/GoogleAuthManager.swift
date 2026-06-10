import Foundation
import Network
import AppKit

// MARK: - OAuth Error

enum GoogleAuthError: Error, LocalizedError {
    case noCredentialsFile
    case invalidCredentialsFile
    case authCancelled
    case noAuthCode
    case tokenExchangeFailed(String)
    case noRefreshToken
    case persistenceError(String)
    case refreshFailed(String)
    case httpServerError(String)

    var errorDescription: String? {
        switch self {
        case .noCredentialsFile:
            return "No Google credentials file found at ~/AI Projects/LMKPI/Resources/google_credentials.json"
        case .invalidCredentialsFile:
            return "Invalid Google credentials file format"
        case .authCancelled:
            return "Authentication was cancelled"
        case .noAuthCode:
            return "Failed to obtain authorization code"
        case .tokenExchangeFailed(let msg):
            return "Token exchange failed: \(msg)"
        case .noRefreshToken:
            return "No stored refresh token — please sign in again"
        case .persistenceError(let msg):
            return "Credential storage error: \(msg)"
        case .refreshFailed(let msg):
            return "Token refresh failed: \(msg)"
        case .httpServerError(let msg):
            return "HTTP server error: \(msg)"
        }
    }
}

// MARK: - Google Auth Manager

/// Central OAuth 2.0 manager. Handles sign-in, token persistence,
/// auto-refresh, and scope management. Gated by `isAuthenticated`.
@MainActor
final class GoogleAuthManager: ObservableObject {
    // MARK: Published State

    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var userEmail: String?
    @Published var userName: String?
    @Published var errorMessage: String?

    // MARK: Internal State

    private var config: GoogleSDKConfig?
    private var currentAccessToken: String?
    private var tokenExpiry: Date = .distantPast
    private(set) var currentScopes: [String] = []
    private var refreshToken: String?
    private var listener: NWListener?
    private var authContinuation: CheckedContinuation<String, Error>?

    // MARK: Configuration

    private func loadConfig() throws -> GoogleSDKConfig {
        if let cached = config { return cached }
        // Path relative to the project directory, inside ~/AI Projects/
        let home = FileManager.default.homeDirectoryForCurrentUser
        let url = home.appendingPathComponent("AI Projects/LMKPI/Resources/google_credentials.json")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw GoogleAuthError.noCredentialsFile
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        do {
            let cfg = try decoder.decode(GoogleSDKConfig.self, from: data)
            config = cfg
            return cfg
        } catch {
            throw GoogleAuthError.invalidCredentialsFile
        }
    }

    // MARK: - Token Persistence (file-based, no Keychain needed for dev builds)

    private var credentialsURL: URL {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = supportDir.appendingPathComponent("LMKPI", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("google_auth.json")
    }

    private func saveCredentials(_ credentials: StoredCredentials) throws {
        let data = try JSONEncoder().encode(credentials)
        try data.write(to: credentialsURL, options: .atomic)
    }

    private func loadCredentials() -> StoredCredentials? {
        guard let data = try? Data(contentsOf: credentialsURL) else { return nil }
        return try? JSONDecoder().decode(StoredCredentials.self, from: data)
    }

    private func deleteCredentials() {
        try? FileManager.default.removeItem(at: credentialsURL)
    }

    // MARK: - Session Restore (called on app launch)

    func restoreSessionIfAvailable() async {
        guard let stored = loadCredentials() else {
            isAuthenticated = false
            return
        }
        refreshToken = stored.refreshToken
        userEmail = stored.userEmail
        userName = stored.userName
        currentScopes = stored.scopes

        do {
            try await refreshAccessToken()
            isAuthenticated = true
        } catch {
            // Refresh failed — user needs to re-auth
            await signOut()
            isAuthenticated = false
        }
    }

    // MARK: - Sign In

    /// Starts the OAuth 2.0 desktop flow with the given scopes.
    /// Opens the Google auth URL in the user's browser, catches the redirect
    /// via a local HTTP server, and exchanges the code for tokens.
    func signIn(with scopes: [String]) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let cfg = try loadConfig()
        currentScopes = scopes

        // Start a local HTTP server on a random port
        let port = try await startRedirectServer()
        let redirectURI = "http://localhost:\(port)"

        // Build the auth URL
        let scopeString = scopes.joined(separator: " ")
        var components = URLComponents(string: cfg.authUri)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: cfg.clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopeString),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]
        guard let authURL = components.url else {
            throw GoogleAuthError.httpServerError("Failed to build auth URL")
        }

        // Open in browser
        await MainActor.run {
            // Try Chrome first per user preference, fallback to default browser
            if let chromeURL = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://www.google.com")!),
               chromeURL.lastPathComponent.contains("Chrome") {
                NSWorkspace.shared.open([authURL], withApplicationAt: chromeURL,
                                        configuration: NSWorkspace.OpenConfiguration())
            } else {
                NSWorkspace.shared.open(authURL)
            }
        }

        // Wait for the redirect server to catch the auth code
        let authCode: String
        do {
            authCode = try await withCheckedThrowingContinuation { continuation in
                self.authContinuation = continuation
            }
        } catch {
            stopRedirectServer()
            throw error
        }
        stopRedirectServer()

        // Exchange auth code for tokens
        try await exchangeCodeForTokens(code: authCode, redirectURI: redirectURI, cfg: cfg)
    }

    // MARK: - Exchange Code for Tokens

    private func exchangeCodeForTokens(code: String, redirectURI: String, cfg: GoogleSDKConfig) async throws {
        var request = URLRequest(url: URL(string: cfg.tokenUri)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "client_id", value: cfg.clientId),
            URLQueryItem(name: "client_secret", value: cfg.clientSecret),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        request.httpBody = bodyComponents.query?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            if let error = try? JSONDecoder().decode(GoogleTokenError.self, from: data) {
                throw GoogleAuthError.tokenExchangeFailed(error.errorDescriptionFull ?? "Unknown error")
            }
            throw GoogleAuthError.tokenExchangeFailed("HTTP \(httpResponse.statusCode)")
        }

        let tokenResponse = try JSONDecoder().decode(GoogleTokenResponse.self, from: data)
        currentAccessToken = tokenResponse.accessToken
        tokenExpiry = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn - 60))

        // Store refresh token
        if let rt = tokenResponse.refreshToken {
            refreshToken = rt
        }
        guard let rt = refreshToken else {
            throw GoogleAuthError.noRefreshToken
        }

        // Fetch user info
        try await fetchUserInfo()

        // Persist credentials
        let stored = StoredCredentials(
            refreshToken: rt,
            scopes: currentScopes,
            userEmail: userEmail,
            userName: userName
        )
        try saveCredentials(stored)
        isAuthenticated = true
    }

    // MARK: - Token Refresh

    /// Refreshes the access_token. Called automatically before API calls.
    func ensureValidAccessToken() async throws -> String {
        if let token = currentAccessToken, Date() < tokenExpiry {
            return token
        }
        try await refreshAccessToken()
        guard let token = currentAccessToken else {
            throw GoogleAuthError.refreshFailed("No access token after refresh")
        }
        return token
    }

    private func refreshAccessToken() async throws {
        guard let rt = refreshToken else {
            throw GoogleAuthError.noRefreshToken
        }
        let cfg = try loadConfig()

        var request = URLRequest(url: URL(string: cfg.tokenUri)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "refresh_token", value: rt),
            URLQueryItem(name: "client_id", value: cfg.clientId),
            URLQueryItem(name: "client_secret", value: cfg.clientSecret),
            URLQueryItem(name: "grant_type", value: "refresh_token")
        ]
        request.httpBody = bodyComponents.query?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            if let error = try? JSONDecoder().decode(GoogleTokenError.self, from: data) {
                throw GoogleAuthError.refreshFailed(error.errorDescriptionFull ?? "Unknown error")
            }
            throw GoogleAuthError.refreshFailed("HTTP \(httpResponse.statusCode)")
        }

        let tokenResponse = try JSONDecoder().decode(GoogleTokenResponse.self, from: data)
        currentAccessToken = tokenResponse.accessToken
        tokenExpiry = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn - 60))

        // Google may issue a new refresh token; update if so
        if let newRT = tokenResponse.refreshToken {
            refreshToken = newRT
            let stored = StoredCredentials(
                refreshToken: newRT,
                scopes: currentScopes,
                userEmail: userEmail,
                userName: userName
            )
            try? saveCredentials(stored)
        }
    }

    // MARK: - Additional Scopes (incremental auth)

    /// Grant additional scopes beyond what's currently authorized.
    /// Re-runs the OAuth flow; Google only prompts for the new scopes.
    func grantAdditionalScopes(_ newScopes: [String]) async throws {
        let allScopes = Array(Set(currentScopes + newScopes))
        try await signIn(with: allScopes)
    }

    // MARK: - User Info

    private func fetchUserInfo() async throws {
        guard let token = currentAccessToken else { return }
        var request = URLRequest(url: URL(string: "https://www.googleapis.com/oauth2/v3/userinfo")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        if let userInfo = try? JSONDecoder().decode(GoogleUserInfo.self, from: data) {
            userEmail = userInfo.email
            userName = userInfo.name
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        currentAccessToken = nil
        refreshToken = nil
        tokenExpiry = .distantPast
        currentScopes = []
        userEmail = nil
        userName = nil
        isAuthenticated = false
        errorMessage = nil
        deleteCredentials()
        stopRedirectServer()
    }

    // MARK: - Local HTTP Redirect Server

    private func startRedirectServer() async throws -> UInt16 {
        stopRedirectServer()  // Clean up any previous

        let params = NWParameters.tcp
        let listener = try NWListener(using: params, on: .any)
        self.listener = listener

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<UInt16, Error>) in
            listener.service = NWListener.Service(name: nil, type: "_http._tcp", txtRecord: nil)

            listener.newConnectionHandler = { [weak self] connection in
                connection.start(queue: .main)
                Task { @MainActor [weak self] in
                    self?.handleOAuthRedirect(connection: connection)
                }
            }

            listener.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    if let port = listener.port?.rawValue {
                        continuation.resume(returning: port)
                    } else {
                        continuation.resume(throwing: GoogleAuthError.httpServerError("No port assigned"))
                    }
                case .failed(let error):
                    continuation.resume(throwing: GoogleAuthError.httpServerError(error.localizedDescription))
                default:
                    break
                }
            }

            listener.start(queue: .main)
        }
    }

    private func handleOAuthRedirect(connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, _, _ in
            guard let self = self, let data = data,
                  let requestStr = String(data: data, encoding: .utf8) else {
                connection.cancel()
                return
            }

            // Parse the HTTP request to extract the auth code
            // The first line contains: GET /?code=...&scope=... HTTP/1.1
            let lines = requestStr.components(separatedBy: "\r\n")
            guard let firstLine = lines.first else {
                connection.cancel()
                return
            }

            let parts = firstLine.components(separatedBy: " ")
            guard parts.count >= 2, let pathPart = parts[safe: 1] else {
                connection.cancel()
                return
            }

            // Extract code from query string
            var authCode: String?
            if let queryStart = pathPart.range(of: "?") {
                let query = String(pathPart[queryStart.upperBound...])
                let params = self.parseQueryString(query)
                authCode = params["code"]
            }

            // Send HTTP response
            let responseBody: String
            if authCode != nil {
                responseBody = """
                <html><body style="font-family:-apple-system,sans-serif;background:#000;color:#fff;display:flex;align-items:center;justify-content:center;height:100vh;margin:0">
                <p style="font-size:18px">Authentication successful. You may close this window.</p>
                </body></html>
                """
            } else {
                responseBody = """
                <html><body style="font-family:-apple-system,sans-serif;background:#000;color:#fff;display:flex;align-items:center;justify-content:center;height:100vh;margin:0">
                <p style="font-size:18px">Authentication failed. No authorization code received.</p>
                </body></html>
                """
            }

            let response = """
            HTTP/1.1 200 OK\r
            Content-Type: text/html\r
            Content-Length: \(responseBody.utf8.count)\r
            \r
            \(responseBody)
            """
            connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ _ in
                connection.cancel()
            }))

            // Resume the auth continuation
            DispatchQueue.main.async {
                if let code = authCode {
                    self.authContinuation?.resume(returning: code)
                } else {
                    self.authContinuation?.resume(throwing: GoogleAuthError.noAuthCode)
                }
                self.authContinuation = nil
            }
        }
    }

    nonisolated private func parseQueryString(_ query: String) -> [String: String] {
        var result: [String: String] = [:]
        for pair in query.components(separatedBy: "&") {
            let components = pair.components(separatedBy: "=")
            guard components.count == 2 else { continue }
            let key = components[0].removingPercentEncoding ?? components[0]
            let value = components[1].removingPercentEncoding ?? components[1]
            result[key] = value
        }
        return result
    }

    private func stopRedirectServer() {
        listener?.cancel()
        listener = nil
    }
}

// MARK: - Safe Array Index

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
