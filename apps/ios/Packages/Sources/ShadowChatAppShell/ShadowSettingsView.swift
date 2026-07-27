import ShadowCoreContracts
import ShadowDesignSystem
import SwiftUI

struct ShadowSettingsView: View {
    let appState: ShadowAppState

    @State private var presentsSecurityCenter = false

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
                        Label(
                            "Gerät: \(appState.session.account?.deviceID ?? "Nicht registriert")",
                            systemImage: appState.security.deviceTrust.symbolName
                        )
                        .foregroundStyle(appState.security.deviceTrust.tint)

                        Button("Verschlüsselung verwalten") {
                            presentsSecurityCenter = true
                        }
                    }

                    Section("Vertrauen") {
                        ForEach(appState.bridges) { bridge in
                            LabeledContent(
                                bridge.kind.displayName,
                                value: bridge.trust.title
                            )
                        }
                    }

                    Section("Mitteilungen") {
                        LabeledContent(
                            "Push",
                            value: appState.pushRegistration.state.title
                        )

                        if appState.pushRegistration.state == .registered {
                            Button(
                                "Push-Verbindung entfernen",
                                role: .destructive
                            ) {
                                Task {
                                    await appState.disablePushNotifications()
                                }
                            }
                        } else {
                            Button("Mitteilungen aktivieren") {
                                Task {
                                    await appState.enablePushNotifications()
                                }
                            }
                            .disabled(appState.isBusy)
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
            .sheet(isPresented: $presentsSecurityCenter) {
                ShadowSecurityCenterView(appState: appState)
            }
        }
    }
}

private extension ShadowPushRegistrationState {
    var title: String {
        switch self {
        case .unavailable:
            "Nicht eingerichtet"
        case .registering:
            "Wird registriert"
        case .registered:
            "Aktiv"
        case .denied:
            "Nicht erlaubt"
        case .failed:
            "Fehlgeschlagen"
        }
    }
}

private extension ShadowDeviceTrustState {
    var symbolName: String {
        switch self {
        case .unknown:
            "shield.lefthalf.filled"
        case .unverified:
            "exclamationmark.shield.fill"
        case .verified:
            "checkmark.shield.fill"
        }
    }

    var tint: Color {
        switch self {
        case .unknown:
            ShadowColors.softText
        case .unverified:
            .orange
        case .verified:
            ShadowColors.whatsAppGreen
        }
    }
}
