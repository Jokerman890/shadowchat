import ShadowCoreContracts
import ShadowDesignSystem
import SwiftUI

struct ShadowBridgeHubView: View {
    let appState: ShadowAppState

    var body: some View {
        NavigationStack {
            ShadowLiquidBackground {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ShadowSpacing.md) {
                        Text("Bridges")
                            .font(.largeTitle.weight(.bold))

                        Text("Externe Netzwerke bleiben von nativen Matrix-Räumen unterscheidbar.")
                            .foregroundStyle(ShadowColors.softText)

                        ForEach(appState.bridges) { bridge in
                            ShadowBridgeCard(
                                bridge: bridge,
                                pair: {
                                    Task { await appState.beginPairing(bridge.kind) }
                                },
                                disconnect: {
                                    Task { await appState.disconnectBridge(bridge.kind) }
                                }
                            )
                        }
                    }
                    .padding(ShadowSpacing.lg)
                }
                .refreshable {
                    await appState.refreshBridges()
                }
            }
            .navigationTitle("Bridges")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct ShadowBridgeCard: View {
    let bridge: ShadowBridgeSnapshot
    let pair: () -> Void
    let disconnect: () -> Void

    var body: some View {
        ShadowGlassPanel(radius: ShadowRadii.card) {
            VStack(alignment: .leading, spacing: ShadowSpacing.md) {
                HStack(spacing: ShadowSpacing.md) {
                    Image(systemName: symbolName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(iconColor)
                        .frame(width: 52, height: 52)
                        .background(iconColor.opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: ShadowSpacing.xs) {
                        Text(bridge.kind.displayName)
                            .font(.headline)
                        Text(bridge.kind.implementationName)
                            .font(.caption)
                            .foregroundStyle(ShadowColors.softText)
                    }

                    Spacer()

                    Text(stateTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(iconColor)
                }

                Label(bridge.trust.title, systemImage: trustSymbol)
                    .font(.subheadline)
                    .foregroundStyle(ShadowColors.softText)

                if let account = bridge.accountLabel {
                    Text(account)
                        .font(.subheadline.monospaced())
                }

                if let warning = bridge.warning {
                    Label(warning, systemImage: "exclamationmark.shield.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }

                if bridge.kind != .matrix, bridge.state != .unavailable {
                    Button(bridge.state.isOperational ? "Verbindung trennen" : "Gerät koppeln") {
                        bridge.state.isOperational ? disconnect() : pair()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(bridge.state.isOperational ? .red : ShadowColors.whatsAppGreen)
                }
            }
            .padding(ShadowSpacing.lg)
        }
    }

    private var symbolName: String {
        switch bridge.kind {
        case .matrix:
            "square.grid.3x3.fill"
        case .whatsApp:
            "phone.bubble.fill"
        case .signal:
            "antenna.radiowaves.left.and.right"
        }
    }

    private var trustSymbol: String {
        bridge.trust == .nativeEncrypted ? "checkmark.shield.fill" : "arrow.triangle.branch"
    }

    private var iconColor: Color {
        switch bridge.state {
        case .connected:
            ShadowColors.whatsAppGreen
        case .degraded, .reconnecting, .pairing:
            .orange
        case .failed, .unavailable:
            .red
        case .notConfigured:
            ShadowColors.softText
        }
    }

    private var stateTitle: String {
        switch bridge.state {
        case .unavailable:
            "Nicht verfügbar"
        case .notConfigured:
            "Nicht verbunden"
        case .pairing:
            "Kopplung"
        case .connected:
            "Verbunden"
        case .degraded:
            "Eingeschränkt"
        case .reconnecting:
            "Neu verbinden"
        case .failed:
            "Fehler"
        }
    }
}

struct ShadowPairingView: View {
    let pairing: ShadowPairingSession
    let confirm: () -> Void
    let cancel: () -> Void

    var body: some View {
        ShadowLiquidBackground {
            VStack(spacing: ShadowSpacing.xl) {
                Image(systemName: "qrcode")
                    .font(.system(size: 92, weight: .regular))
                    .foregroundStyle(ShadowColors.whatsAppGreen)
                    .accessibilityLabel("QR-Kopplungscode")

                VStack(spacing: ShadowSpacing.sm) {
                    Text("\(pairing.bridge.displayName) koppeln")
                        .font(.title2.weight(.bold))
                    Text("Öffne die Geräteverwaltung des externen Messengers und bestätige anschließend die lokale Vorschau.")
                        .foregroundStyle(ShadowColors.softText)
                        .multilineTextAlignment(.center)
                }

                Text(pairing.payload)
                    .font(.caption.monospaced())
                    .lineLimit(2)
                    .padding(ShadowSpacing.md)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: ShadowRadii.control))

                HStack {
                    Button("Abbrechen", action: cancel)
                        .buttonStyle(.bordered)
                    Button("Kopplung bestätigen", action: confirm)
                        .buttonStyle(.borderedProminent)
                        .tint(ShadowColors.whatsAppGreen)
                }
            }
            .padding(ShadowSpacing.xl)
        }
    }
}
