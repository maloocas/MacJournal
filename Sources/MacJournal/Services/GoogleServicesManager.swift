import Foundation

// MARK: - GoogleService Protocol

/// Every Google Workspace integration (Calendar, Mail, Drive, Tasks, etc.)
/// conforms to this protocol. The registry handles scopes, enable/disable,
/// and configuring services when auth is available.
@MainActor
protocol GoogleService: AnyObject {
    /// Unique short name for persistence (e.g. "calendar", "mail")
    var name: String { get }

    /// Human-readable name for the UI (e.g. "Calendar", "Gmail")
    var displayName: String { get }

    /// SF Symbol name for use in navigation / settings
    var icon: String { get }

    /// OAuth scopes this service requires
    var requiredScopes: [String] { get }

    /// Whether the user has enabled this service
    var isEnabled: Bool { get set }

    /// Called after auth is available and scopes are granted.
    /// Use this to fetch initial data or warm caches.
    func configure(with auth: GoogleAuthManager) async throws
}

// MARK: - Google Services Manager

/// Central registry for all Google Workspace integrations.
/// Handles registration, enable/disable, scope negotiation,
/// and lifecycle callbacks when auth state changes.
@MainActor
final class GoogleServicesManager: ObservableObject {
    // MARK: Published State

    @Published var services: [any GoogleService] = []
    @Published var enabledServiceNames: Set<String> = []

    // MARK: Internal

    private var authManager: GoogleAuthManager?
    private var configured: Bool = false

    private let enabledKey = "google_services_enabled"

    // MARK: - Registration

    /// Register a service. Call this in the App init for all available integrations.
    /// The service won't be configured until enabled + auth is available.
    func register(_ service: some GoogleService) {
        services.append(service)
        loadEnabledState()
    }

    /// Configure all registered services with the auth manager.
    /// Call after auth succeeds (or is restored on launch).
    func configureAll(with auth: GoogleAuthManager) async {
        authManager = auth
        loadEnabledState()

        for service in services {
            guard service.isEnabled else { continue }
            // Check if all required scopes are already granted
            let missing = service.requiredScopes.filter { !auth.currentScopes.contains($0) }
            if missing.isEmpty {
                do {
                    try await service.configure(with: auth)
                } catch {
                    print("[GoogleServices] Failed to configure \(service.name): \(error)")
                }
            }
        }
        configured = true
    }

    // MARK: - Enable / Disable

    /// Enable a service. If its scopes aren't yet granted,
    /// triggers incremental OAuth to grant them, then configures the service.
    func enable(_ serviceName: String) async throws {
        guard let auth = authManager else {
            throw GoogleServicesError.notAuthenticated
        }
        guard let idx = services.firstIndex(where: { $0.name == serviceName }) else {
            throw GoogleServicesError.serviceNotFound(serviceName)
        }

        let missing = services[idx].requiredScopes.filter { !auth.currentScopes.contains($0) }
        if !missing.isEmpty {
            try await auth.grantAdditionalScopes(missing)
        }

        try await services[idx].configure(with: auth)
        services[idx].isEnabled = true
        enabledServiceNames.insert(serviceName)
        persistEnabledState()
    }

    func disable(_ serviceName: String) {
        guard let idx = services.firstIndex(where: { $0.name == serviceName }) else { return }
        services[idx].isEnabled = false
        enabledServiceNames.remove(serviceName)
        persistEnabledState()
    }

    // MARK: - Query

    func service(named name: String) -> (any GoogleService)? {
        services.first { $0.name == name }
    }

    func isServiceEnabled(_ name: String) -> Bool {
        enabledServiceNames.contains(name)
    }

    // MARK: - Aggregate Scopes

    /// All scopes needed by all registered services (for future use).
    func allScopes() -> [String] {
        var scopes = GoogleScope.allStringValues  // base userinfo scopes
        for service in services {
            scopes.append(contentsOf: service.requiredScopes)
        }
        return Array(Set(scopes))
    }

    /// Scopes needed by currently enabled services only.
    func activeScopes() -> [String] {
        var scopes = GoogleScope.allStringValues
        for service in services where service.isEnabled {
            scopes.append(contentsOf: service.requiredScopes)
        }
        return Array(Set(scopes))
    }

    // MARK: - Persistence

    private func loadEnabledState() {
        if let raw = UserDefaults.standard.stringArray(forKey: enabledKey) {
            enabledServiceNames = Set(raw)
            for i in services.indices {
                services[i].isEnabled = enabledServiceNames.contains(services[i].name)
            }
        }
    }

    private func persistEnabledState() {
        UserDefaults.standard.set(Array(enabledServiceNames), forKey: enabledKey)
    }
}

// MARK: - Errors

enum GoogleServicesError: Error, LocalizedError {
    case notAuthenticated
    case serviceNotFound(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated with Google"
        case .serviceNotFound(let name):
            return "Service not found: \(name)"
        }
    }
}
