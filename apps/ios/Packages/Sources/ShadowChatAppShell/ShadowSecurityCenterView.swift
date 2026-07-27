import ShadowCoreContracts
import ShadowDesignSystem
import SwiftUI

struct ShadowSecurityCenterView: View {
    let appState: ShadowAppState

    @Environment(\.dismiss) private var dismiss
    @State private var recoveryKey = ""
    @State private var confirmsKeyRotation = false

    var body: some View {
        NavigationStack {
            ShadowLiquidBackground {
                Form {
                    statusSection
                    verificationSection
                    recoverySection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Verschlüsselung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
            .task {
                await appState.refreshSecurity()
            }
            .confirmationDialog(
                "Wiederherstellungsschlüssel erneuern?",
                isPresented: $confirmsKeyRotation,
                titleVisibility: .visible
            ) {
                Button("Neuen Schlüssel erzeugen", role: .destructive) {
                    Task {
                        await appState.generateRecoveryKey()
                    }
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Der bisherige Schlüssel wird ungültig. Bewahre den neuen Schlüssel sicher außerhalb dieses Geräts auf.")
            }
        }
        .interactiveDismissDisabled(appState.generatedRecoveryKey != nil)
    }

    private var statusSection: some View {
        Section("Status") {
            LabeledContent(
                "Dieses Gerät",
                value: appState.security.deviceTrust.title
            )
            LabeledContent(
                "Wiederherstellung",
                value: appState.security.recovery.title
            )
            LabeledContent(
                "Schlüssel-Backup",
                value: appState.security.keyBackup.title
            )
        }
    }

    @ViewBuilder
    private var verificationSection: some View {
        Section("Geräteverifikation") {
            switch appState.verificationUpdate {
            case .comparing(let emojis):
                Text("Vergleiche diese Symbole mit deinem bereits verifizierten Matrix-Gerät.")
                    .font(.footnote)
                    .foregroundStyle(ShadowColors.softText)

                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible()),
                        count: 4
                    ),
                    spacing: ShadowSpacing.md
                ) {
                    ForEach(emojis, id: \.self) { emoji in
                        VStack(spacing: ShadowSpacing.xs) {
                            Text(emoji.symbol)
                                .font(.largeTitle)
                            Text(emoji.description)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }

                HStack {
                    Button("Stimmen nicht überein", role: .destructive) {
                        Task {
                            await appState.declineDeviceVerification()
                        }
                    }
                    Button("Stimmen überein") {
                        Task {
                            await appState.approveDeviceVerification()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ShadowColors.whatsAppGreen)
                }
            case .requested, .accepted:
                HStack {
                    ProgressView()
                    Text("Bestätige die Anfrage auf einem verifizierten Gerät.")
                }
                Button("Verifikation abbrechen", role: .cancel) {
                    Task {
                        await appState.cancelDeviceVerification()
                    }
                }
            case .verified:
                Label(
                    "Dieses Gerät ist verifiziert.",
                    systemImage: "checkmark.shield.fill"
                )
                .foregroundStyle(ShadowColors.whatsAppGreen)
            case .failed:
                Label(
                    "Die Verifikation ist fehlgeschlagen.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .foregroundStyle(.orange)
                verificationStartButton
            case .cancelled, .none:
                verificationStartButton
            }
        }
    }

    private var verificationStartButton: some View {
        Button("Mit einem anderen Gerät verifizieren") {
            Task {
                await appState.beginDeviceVerification()
            }
        }
        .disabled(
            appState.isBusy
                || appState.security.deviceTrust == .verified
        )
    }

    @ViewBuilder
    private var recoverySection: some View {
        Section("Recovery") {
            if let generatedKey = appState.generatedRecoveryKey {
                Label(
                    "Speichere diesen Schlüssel jetzt. ShadowChat zeigt ihn nach dem Schließen nicht erneut an.",
                    systemImage: "key.fill"
                )
                .font(.footnote)
                .foregroundStyle(.orange)

                Text(generatedKey)
                    .font(.body.monospaced())
                    .textSelection(.enabled)

                ShareLink(
                    item: generatedKey,
                    subject: Text("ShadowChat Wiederherstellungsschlüssel")
                ) {
                    Label("Sicher exportieren", systemImage: "square.and.arrow.up")
                }

                Button("Ich habe den Schlüssel gesichert") {
                    appState.clearGeneratedRecoveryKey()
                }
                .buttonStyle(.borderedProminent)
                .tint(ShadowColors.whatsAppGreen)
            } else {
                SecureField(
                    "Wiederherstellungsschlüssel",
                    text: $recoveryKey
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                Button("Verschlüsselung wiederherstellen") {
                    Task {
                        if await appState.recoverEncryption(
                            recoveryKey: recoveryKey
                        ) {
                            recoveryKey = ""
                        }
                    }
                }
                .disabled(
                    recoveryKey
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .isEmpty
                        || appState.isBusy
                )

                Button(
                    appState.security.recovery == .disabled
                        ? "Wiederherstellung einrichten"
                        : "Schlüssel erneuern"
                ) {
                    confirmsKeyRotation = true
                }
                .disabled(appState.isBusy)
            }
        } footer: {
            Text("Recovery lädt verschlüsselte Raumschlüssel aus deinem Matrix-Schlüssel-Backup.")
        }
    }
}

private extension ShadowDeviceTrustState {
    var title: String {
        switch self {
        case .unknown:
            "Status wird geladen"
        case .unverified:
            "Nicht verifiziert"
        case .verified:
            "Verifiziert"
        }
    }
}

private extension ShadowRecoveryState {
    var title: String {
        switch self {
        case .unknown:
            "Status wird geladen"
        case .disabled:
            "Nicht eingerichtet"
        case .incomplete:
            "Aktion erforderlich"
        case .settingUp:
            "Wird eingerichtet"
        case .enabled:
            "Aktiv"
        }
    }
}

private extension ShadowKeyBackupState {
    var title: String {
        switch self {
        case .unknown:
            "Nicht aktiv"
        case .enabling:
            "Wird aktiviert"
        case .enabled:
            "Aktiv"
        case .disabling:
            "Wird deaktiviert"
        }
    }
}
