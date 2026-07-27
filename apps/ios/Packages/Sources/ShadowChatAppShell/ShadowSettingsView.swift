import ShadowCoreContracts
import ShadowDesignSystem
import SwiftUI

struct ShadowSettingsView: View {
    let appState: ShadowAppState

    @State private var appLockEnabled = true
    @State private var readReceiptsEnabled = true
    @State private var linkPreviewsEnabled = false

    var body: some View {
        NavigationStack {
            ShadowLiquidBackground {
                Form {
                    Section("Konto") {
                        LabeledContent(
                            "Benutzer",
                            value: appState.session.account?.userID ?? "Unbekannt"
                        )
                        LabeledContent(
                            "Homeserver",
                            value: appState.session.account?.homeserver.host ?? "Unbekannt"
                        )
                        LabeledContent(
                            "Laufzeit",
                            value: appState.session.environment == .matrix ? "Matrix Rust SDK" : "Lokale Vorschau"
                        )
                    }

                    Section("Security Center") {
                        Toggle("App-Sperre", isOn: $appLockEnabled)
                        Toggle("Lesebestätigungen", isOn: $readReceiptsEnabled)
                        Toggle("Link-Vorschauen", isOn: $linkPreviewsEnabled)

                        Label(
                            "Gerät: \(appState.session.account?.deviceID ?? "Nicht registriert")",
                            systemImage: "checkmark.shield.fill"
                        )
                        .foregroundStyle(ShadowColors.whatsAppGreen)
                    }

                    Section("Vertrauen") {
                        ForEach(appState.bridges) { bridge in
                            LabeledContent(
                                bridge.kind.displayName,
                                value: bridge.trust.title
                            )
                        }
                    }

                    Section {
                        Button("Abmelden", role: .destructive) {
                            Task { await appState.signOut() }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Einstellungen")
        }
    }
}
