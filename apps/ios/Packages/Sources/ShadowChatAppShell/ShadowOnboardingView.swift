import ShadowCoreContracts
import ShadowDesignSystem
import SwiftUI

struct ShadowOnboardingView: View {
    let appState: ShadowAppState

    @State private var homeserver = "https://matrix.org"
    @State private var username = ""
    @State private var password = ""
    @State private var oauthPresenter = ShadowOAuthPresenter()

    var body: some View {
        ShadowLiquidBackground {
            ScrollView {
                VStack(spacing: ShadowSpacing.xl) {
                    hero
                    loginPanel
                    trustPanel
                }
                .frame(maxWidth: 620)
                .padding(ShadowSpacing.xl)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var hero: some View {
        VStack(spacing: ShadowSpacing.md) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 84, height: 84)
                .background(shadowAccentGradient, in: Circle())

            Text("ShadowChat")
                .font(.largeTitle.weight(.bold))

            Text("Private Matrix-Nachrichten in einer ruhigen, nativen iOS-Oberfläche.")
                .font(.body)
                .foregroundStyle(ShadowColors.softText)
                .multilineTextAlignment(.center)
        }
    }

    private var loginPanel: some View {
        ShadowGlassPanel {
            VStack(alignment: .leading, spacing: ShadowSpacing.lg) {
                Label(panelTitle, systemImage: panelSymbol)
                    .font(.headline)
                    .foregroundStyle(ShadowColors.whatsAppGreen)

                Text(panelDescription)
                    .font(.subheadline)
                    .foregroundStyle(ShadowColors.softText)

                TextField("Homeserver", text: $homeserver)
                    .textContentType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .shadowField()

                if showsCredentials {
                    TextField(usernameTitle, text: $username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .shadowField()

                    if appState.authenticationDiscovery?.mode == .password
                        || appState.session.environment == .localPreview {
                        SecureField("Passwort", text: $password)
                            .textContentType(.password)
                            .shadowField()
                    }
                }

                Button {
                    primaryAction()
                } label: {
                    HStack {
                        if appState.isBusy {
                            ProgressView()
                                .tint(.black)
                        }
                        Text(buttonTitle)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ShadowSpacing.md)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.black)
                .background(shadowAccentGradient, in: Capsule())
                .disabled(
                    appState.isBusy
                        || !primaryActionEnabled
                )
                .accessibilityHint(accessibilityHint)

                if appState.authenticationDiscovery != nil,
                   appState.session.environment == .matrix {
                    Button("Anderen Homeserver prüfen") {
                        Task {
                            await appState.resetAuthenticationDiscovery()
                        }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(ShadowSpacing.xl)
        }
    }

    private var trustPanel: some View {
        HStack(alignment: .top, spacing: ShadowSpacing.md) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(ShadowColors.whatsAppGreen)
            Text("Der Live-Adapter ist als eigene Matrix-Rust-SDK-Grenze vorgesehen. Bridge-Räume erhalten sichtbar reduzierte oder externe Trust-Signale.")
                .font(.footnote)
                .foregroundStyle(ShadowColors.softText)
        }
    }

    private var panelTitle: String {
        appState.session.environment == .matrix
            ? "Mit Matrix anmelden"
            : "Lokale Produktvorschau"
    }

    private var panelSymbol: String {
        appState.session.environment == .matrix ? "lock.shield.fill" : "hammer.fill"
    }

    private var panelDescription: String {
        if appState.session.environment == .matrix {
            switch appState.authenticationDiscovery?.mode {
            case .oauth:
                return "Dieser Homeserver verwendet eine sichere OIDC/MAS-Anmeldung."
            case .password:
                return "Dieser Homeserver unterstützt die klassische Matrix-Anmeldung."
            case .unsupported:
                return "Der Homeserver bietet keine unterstützte Anmeldemethode an."
            case nil:
                return "ShadowChat prüft zuerst die vom Homeserver angebotene Anmeldemethode."
            }
        }
        return "Dieser Build verwendet den austauschbaren Preview-Service. Er sendet keine Zugangsdaten und behauptet keine echte Matrix-Sitzung."
    }

    private var buttonTitle: String {
        if appState.session.environment == .localPreview {
            return "Lokale Vorschau öffnen"
        }
        switch appState.authenticationDiscovery?.mode {
        case .oauth:
            return "Mit Identitätsanbieter anmelden"
        case .password:
            return "Sicher anmelden"
        case .unsupported:
            return "Nicht unterstützt"
        case nil:
            return "Homeserver prüfen"
        }
    }

    private var accessibilityHint: String {
        if appState.session.environment == .localPreview {
            return "Öffnet ausschließlich lokale Beispieldaten"
        }
        return appState.authenticationDiscovery == nil
            ? "Prüft die Anmeldemethoden des Matrix-Homeservers"
            : "Meldet das Konto am angegebenen Matrix-Homeserver an"
    }

    private var showsCredentials: Bool {
        appState.session.environment == .localPreview
            || appState.authenticationDiscovery?.mode == .password
            || appState.authenticationDiscovery?.mode == .oauth
    }

    private var usernameTitle: String {
        appState.authenticationDiscovery?.mode == .oauth
            ? "Benutzername oder E-Mail (optional)"
            : "Benutzername"
    }

    private var primaryActionEnabled: Bool {
        guard URL(string: homeserver) != nil else {
            return false
        }
        if appState.session.environment == .localPreview {
            return !username.trimmingCharacters(in: .whitespaces).isEmpty
        }
        switch appState.authenticationDiscovery?.mode {
        case .oauth:
            return true
        case .password:
            return !username.trimmingCharacters(in: .whitespaces).isEmpty
                && !password.isEmpty
        case .unsupported:
            return false
        case nil:
            return true
        }
    }

    private func primaryAction() {
        guard let serverURL = URL(string: homeserver) else { return }
        if appState.session.environment == .matrix,
           appState.authenticationDiscovery == nil {
            Task {
                await appState.discoverAuthentication(homeserver: serverURL)
            }
            return
        }
        if appState.authenticationDiscovery?.mode == .oauth {
            beginOAuthSignIn(homeserver: serverURL)
            return
        }

        let request = ShadowLoginRequest(
            homeserver: serverURL,
            username: username,
            password: appState.session.environment == .matrix
                ? password
                : "local-preview-not-a-credential",
            deviceDisplayName: "ShadowChat iOS Preview"
        )
        Task {
            await appState.signIn(request)
        }
    }

    private func beginOAuthSignIn(homeserver: URL) {
        Task {
            guard let authorization = await appState.beginOAuthSignIn(
                homeserver: homeserver,
                loginHint: username
            ) else {
                return
            }
            do {
                let callbackURL = try await oauthPresenter.authenticate(
                    using: authorization.authorizationURL,
                    callbackScheme: authorization.callbackScheme
                )
                await appState.completeOAuthSignIn(callbackURL: callbackURL)
            } catch {
                await appState.cancelOAuthSignIn(error: error)
            }
        }
    }
}

private extension View {
    func shadowField() -> some View {
        padding(ShadowSpacing.md)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: ShadowRadii.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ShadowRadii.control, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            )
    }
}
