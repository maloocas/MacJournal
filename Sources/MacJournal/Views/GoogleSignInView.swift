import SwiftUI

// MARK: - Google Sign-In View (Auth Gate)

/// Full-window view shown when the user is not authenticated with Google.
/// This is the first thing the user sees on app launch before auth.
struct GoogleSignInView: View {
    @EnvironmentObject var authManager: GoogleAuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isSigningIn: Bool = false
    @State private var localError: String?

    var body: some View {
        ZStack {
            themeManager.colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Branding
                VStack(spacing: 24) {
                    // App icon placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(themeManager.colors.accent.opacity(0.08))
                            .frame(width: 80, height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(themeManager.colors.border, lineWidth: 1)
                            )

                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(themeManager.colors.accent)
                    }

                    Text("MacJournal")
                        .font(.system(size: 32, weight: .black))
                        .textCase(.uppercase)
                        .tracking(6)
                        .foregroundColor(themeManager.colors.textPrimary)

                    Text("Analytics Engine")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.colors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(3)
                }

                Spacer()

                // Sign-in card
                VStack(spacing: 20) {
                    Text("Sign in to continue")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.colors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(2)

                    Button(action: startSignIn) {
                        HStack(spacing: 12) {
                            if isSigningIn {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: themeManager.colors.background))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "g.circle.fill")
                                    .font(.system(size: 18))
                            }

                            Text(isSigningIn ? "Signing in..." : "Sign in with Google")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(themeManager.colors.background)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 0)
                                .fill(themeManager.colors.accent)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isSigningIn)
                    .opacity(isSigningIn ? 0.7 : 1)

                    // Error display
                    if let error = localError ?? authManager.errorMessage {
                        Text(error)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.colors.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // Stored user hint (stale session)
                    if let email = authManager.userEmail, !authManager.isAuthenticated {
                        VStack(spacing: 6) {
                            Text("Previously signed in as")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(themeManager.colors.textMuted)
                            Text(email)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(themeManager.colors.textSecondary)
                        }
                    }
                }
                .padding(40)
                .background(themeManager.colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(themeManager.colors.borderFaint, lineWidth: 1)
                )

                Spacer()
            }
            .padding(.horizontal, 40)
        }
        .frame(minWidth: 600, minHeight: 450)
    }

    private func startSignIn() {
        isSigningIn = true
        localError = nil

        Task {
            do {
                // Sign in with base scopes (user email + profile).
                // Services that need additional scopes will request them on enable.
                let scopes = [
                    GoogleScope.userinfoEmail.rawValue,
                    GoogleScope.userinfoProfile.rawValue
                ]
                try await authManager.signIn(with: scopes)
                // On success, isAuthenticated flips to true and the
                // parent view switches to ContentView automatically
            } catch {
                localError = error.localizedDescription
                isSigningIn = false
            }
        }
    }
}
