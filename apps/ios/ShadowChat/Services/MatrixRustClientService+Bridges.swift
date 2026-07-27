import Foundation
import ShadowCoreContracts

extension MatrixRustClientService {
    func bridgeSnapshots() async throws -> [ShadowBridgeSnapshot] {
        let matrixState: ShadowBridgeConnectionState = sessionSnapshot
            .state
            .grantsMessagingAccess ? .connected : .notConfigured

        return [
            ShadowBridgeSnapshot(
                kind: .matrix,
                state: matrixState,
                trust: .nativeEncrypted,
                accountLabel: sessionSnapshot.account?.userID,
                capabilities: Set(ShadowBridgeCapability.allCases),
                lastSyncAt: sessionSnapshot.lastSyncAt
            ),
            externalBridgeSnapshot(kind: .whatsApp),
            externalBridgeSnapshot(kind: .signal)
        ]
    }

    func beginPairing(
        bridge: ShadowBridgeKind,
        deviceName: String
    ) async throws -> ShadowPairingSession {
        throw ShadowServiceError.bridgeUnavailable
    }

    func confirmPairing(sessionID: UUID) async throws -> ShadowBridgeSnapshot {
        throw ShadowServiceError.bridgeUnavailable
    }

    func cancelPairing(sessionID: UUID) async {}

    func disconnectBridge(
        _ bridge: ShadowBridgeKind,
        revokeRemoteSession: Bool
    ) async throws -> ShadowBridgeSnapshot {
        throw ShadowServiceError.bridgeUnavailable
    }

    func puppets(for bridge: ShadowBridgeKind) async throws -> [ShadowUserPuppet] {
        guard bridge == .matrix else {
            throw ShadowServiceError.bridgeUnavailable
        }
        return []
    }

    private func externalBridgeSnapshot(kind: ShadowBridgeKind) -> ShadowBridgeSnapshot {
        ShadowBridgeSnapshot(
            kind: kind,
            state: .unavailable,
            trust: .externalEncryptedTransport,
            capabilities: [],
            warning: "\(kind.implementationName) ist für diesen Build nicht konfiguriert."
        )
    }
}
