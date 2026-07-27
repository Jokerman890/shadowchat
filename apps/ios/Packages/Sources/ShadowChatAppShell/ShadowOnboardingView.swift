import ShadowCoreContracts
import ShadowDesignSystem
import SwiftUI

struct ShadowOnboardingView: View {
    let appState: ShadowAppState

    @State private var homeserver = "https://matrix.org"
    @State private var username = "shadow"
    @State private var password = ""

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

                TextField("Anzeigename", text: $username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .shadowField()

                if appState.session.environment == .matrix {
                    SecureField("Passwort", text: $password)
                        .textContentType(.password)
                        .shadowField()
                }

                Button {
                    signIn()
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
                        || username.trimmingCharacters(in: .whitespaces).isEmpty
                        || (appState.session.environment == .matrix && password.isEmpty)
                )
                .accessibilityHint(accessibilityHint)
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
            return "Die Anmeldung wird vom injizierten Matrix-Rust-SDK-Service verarbeitet."
        }
        return "Dieser Build verwendet den austauschbaren Preview-Service. Er sendet keine Zugangsdaten und behauptet keine echte Matrix-Sitzung."
    }

    private var buttonTitle: String {
        appState.session.environment == .matrix
            ? "Sicher anmelden"
            : "Lokale Vorschau öffnen"
    }

    private var accessibilityHint: String {
        appState.session.environment == .matrix
            ? "Meldet das Konto am angegebenen Matrix-Homeserver an"
            : "Öffnet ausschließlich lokale Beispieldaten"
    }

    private func signIn() {
        guard let serverURL = URL(string: homeserver) else { return }
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
