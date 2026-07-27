import Foundation
import ShadowCoreContracts

actor PreviewShadowClientService: ShadowClientService {
    nonisolated let runtimeEnvironment = ShadowRuntimeEnvironment.localPreview

    private var session: ShadowSessionSnapshot
    private let restoredSession: ShadowSessionSnapshot?
    private let failsSyncStart: Bool
    private var pushRegistration: ShadowPushRegistration
    private var bridges: [ShadowBridgeKind: ShadowBridgeSnapshot]
    private var pairingSessions: [UUID: ShadowPairingSession] = [:]

    init(
        restoredSession: ShadowSessionSnapshot? = nil,
        pushRegistration: ShadowPushRegistration = .unavailable,
        failsSyncStart: Bool = false
    ) {
        session = restoredSession ?? .signedOutPreview
        self.restoredSession = restoredSession
        self.pushRegistration = pushRegistration
        self.failsSyncStart = failsSyncStart
        bridges = [
            .matrix: ShadowBridgeSnapshot(
                kind: .matrix,
                state: .notConfigured,
                trust: .nativeEncrypted,
                capabilities: Set(ShadowBridgeCapability.allCases)
            ),
            .whatsApp: ShadowBridgeSnapshot(
                kind: .whatsApp,
                state: .notConfigured,
                trust: .externalEncryptedTransport,
                capabilities: [.text, .media, .reactions, .replies, .readReceipts, .typing, .voiceMessages],
                warning: "Bridge-Räume haben einen eigenen Vertrauenskontext."
            ),
            .signal: ShadowBridgeSnapshot(
                kind: .signal,
                state: .notConfigured,
                trust: .externalEncryptedTransport,
                capabilities: [.text, .media, .reactions, .replies, .readReceipts, .typing, .voiceMessages, .disappearingMessages],
                warning: "Bridge-Räume haben einen eigenen Vertrauenskontext."
            )
        ]
    }

    func discoverAuthentication(
        homeserver: URL
    ) async throws -> ShadowAuthenticationDiscovery {
        ShadowAuthenticationDiscovery(
            homeserver: homeserver,
            mode: .password,
            supportsAccountCreation: false
        )
    }

    func beginOAuthSignIn(
        homeserver: URL,
        loginHint: String?
    ) async throws -> ShadowOAuthAuthorization {
        throw ShadowServiceError.unsupportedOperation
    }

    func completeOAuthSignIn(
        callbackURL: URL
    ) async throws -> ShadowSessionSnapshot {
        throw ShadowServiceError.unsupportedOperation
    }

    func cancelOAuthSignIn() async {}

    func securitySnapshot() async throws -> ShadowSecuritySnapshot {
        .unknown
    }

    func securityUpdates() async -> AsyncStream<ShadowSecuritySnapshot> {
        AsyncStream { continuation in
            continuation.yield(.unknown)
            continuation.finish()
        }
    }

    func deviceVerificationUpdates() async -> AsyncStream<ShadowDeviceVerificationUpdate> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func beginDeviceVerification() async throws {
        throw ShadowServiceError.unsupportedOperation
    }

    func approveDeviceVerification() async throws {
        throw ShadowServiceError.unsupportedOperation
    }

    func declineDeviceVerification() async throws {
        throw ShadowServiceError.unsupportedOperation
    }

    func cancelDeviceVerification() async {}

    func generateRecoveryKey(passphrase: String?) async throws -> String {
        throw ShadowServiceError.unsupportedOperation
    }

    func recoverEncryption(recoveryKey: String) async throws -> ShadowSecuritySnapshot {
        throw ShadowServiceError.unsupportedOperation
    }

    func registerPush(
        deviceToken: Data,
        gatewayURL: URL
    ) async throws -> ShadowPushRegistration {
        throw ShadowServiceError.unsupportedOperation
    }

    func currentPushRegistration() async -> ShadowPushRegistration {
        pushRegistration
    }

    func unregisterPush() async throws {}

    func restoreSession() async throws -> ShadowSessionSnapshot? {
        restoredSession
    }

    func signIn(_ request: ShadowLoginRequest) async throws -> ShadowSessionSnapshot {
        guard request.homeserver.scheme == "https",
              request.homeserver.host != nil else {
            throw ShadowServiceError.invalidHomeserver
        }

        let normalizedUser = request.username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedUser.isEmpty else {
            throw ShadowServiceError.invalidCredentials
        }

        let serverName = request.homeserver.host ?? "preview.invalid"
        let matrixUserID = normalizedUser.hasPrefix("@")
            ? normalizedUser
            : "@\(normalizedUser):\(serverName)"
        let displayName = normalizedUser
            .trimmingCharacters(in: CharacterSet(charactersIn: "@"))
            .split(separator: ":")
            .first
            .map(String.init) ?? "ShadowChat"

        let account = ShadowAccount(
            id: matrixUserID,
            userID: matrixUserID,
            displayName: displayName,
            homeserver: request.homeserver,
            deviceID: "SHADOWCHAT-PREVIEW"
        )
        session = ShadowSessionSnapshot(
            state: .active,
            account: account,
            capabilities: Set(ShadowSessionCapability.allCases),
            environment: .localPreview
        )
        bridges[.matrix] = ShadowBridgeSnapshot(
            kind: .matrix,
            state: .connected,
            trust: .nativeEncrypted,
            accountLabel: matrixUserID,
            capabilities: Set(ShadowBridgeCapability.allCases),
            lastSyncAt: Date()
        )
        return session
    }

    func currentSession() async -> ShadowSessionSnapshot {
        session
    }

    func startSync() async throws -> ShadowSessionSnapshot {
        if failsSyncStart {
            throw ShadowServiceError.networkUnavailable
        }
        guard session.state == .active else {
            throw ShadowServiceError.sessionExpired
        }
        session = ShadowSessionSnapshot(
            state: .syncing,
            account: session.account,
            capabilities: session.capabilities,
            lastSyncAt: Date(),
            environment: session.environment
        )
        return session
    }

    func stopSync() async {
        guard session.state == .syncing else { return }
        session = ShadowSessionSnapshot(
            state: .active,
            account: session.account,
            capabilities: session.capabilities,
            lastSyncAt: session.lastSyncAt,
            environment: session.environment
        )
    }

    func signOut(eraseLocalData: Bool) async throws -> ShadowSessionSnapshot {
        session = .signedOutPreview
        pairingSessions.removeAll()
        for kind in ShadowBridgeKind.allCases {
            let trust: ShadowBridgeTrust = kind == .matrix
                ? .nativeEncrypted
                : .externalEncryptedTransport
            bridges[kind] = ShadowBridgeSnapshot(
                kind: kind,
                state: .notConfigured,
                trust: trust,
                capabilities: bridges[kind]?.capabilities ?? []
            )
        }
        return session
    }

    func bridgeSnapshots() async throws -> [ShadowBridgeSnapshot] {
        ShadowBridgeKind.allCases.compactMap { bridges[$0] }
    }

    func beginPairing(
        bridge: ShadowBridgeKind,
        deviceName: String
    ) async throws -> ShadowPairingSession {
        guard bridge != .matrix else {
            throw ShadowServiceError.unsupportedOperation
        }
        guard session.state.grantsMessagingAccess else {
            throw ShadowServiceError.sessionExpired
        }

        let pairing = ShadowPairingSession(
            bridge: bridge,
            state: .ready,
            payload: "shadowchat://pair/\(bridge.rawValue)/\(UUID().uuidString)",
            deviceName: deviceName,
            expiresAt: Date().addingTimeInterval(120)
        )
        pairingSessions[pairing.id] = pairing
        bridges[bridge] = ShadowBridgeSnapshot(
            kind: bridge,
            state: .pairing,
            trust: .externalEncryptedTransport,
            capabilities: bridges[bridge]?.capabilities ?? []
        )
        return pairing
    }

    func confirmPairing(sessionID: UUID) async throws -> ShadowBridgeSnapshot {
        guard let pairing = pairingSessions[sessionID] else {
            throw ShadowServiceError.pairingExpired
        }
        guard pairing.expiresAt > Date() else {
            pairingSessions[sessionID] = nil
            throw ShadowServiceError.pairingExpired
        }

        let snapshot = ShadowBridgeSnapshot(
            kind: pairing.bridge,
            state: .connected,
            trust: .externalEncryptedTransport,
            accountLabel: pairing.bridge == .whatsApp ? "+49 •••• 2048" : "Signal-Gerät",
            capabilities: bridges[pairing.bridge]?.capabilities ?? [],
            lastSyncAt: Date(),
            warning: "Nachrichten durchlaufen einen externen Bridge-Dienst."
        )
        pairingSessions[sessionID] = nil
        bridges[pairing.bridge] = snapshot
        return snapshot
    }

    func cancelPairing(sessionID: UUID) async {
        guard let pairing = pairingSessions.removeValue(forKey: sessionID) else { return }
        bridges[pairing.bridge] = ShadowBridgeSnapshot(
            kind: pairing.bridge,
            state: .notConfigured,
            trust: .externalEncryptedTransport,
            capabilities: bridges[pairing.bridge]?.capabilities ?? []
        )
    }

    func disconnectBridge(
        _ bridge: ShadowBridgeKind,
        revokeRemoteSession: Bool
    ) async throws -> ShadowBridgeSnapshot {
        guard bridge != .matrix else {
            throw ShadowServiceError.unsupportedOperation
        }
        let snapshot = ShadowBridgeSnapshot(
            kind: bridge,
            state: .notConfigured,
            trust: .externalEncryptedTransport,
            capabilities: bridges[bridge]?.capabilities ?? []
        )
        bridges[bridge] = snapshot
        return snapshot
    }

    func puppets(for bridge: ShadowBridgeKind) async throws -> [ShadowUserPuppet] {
        guard bridges[bridge]?.state.isOperational == true else { return [] }
        return [
            ShadowUserPuppet(
                id: "\(bridge.rawValue)-preview-contact",
                bridge: bridge,
                matrixUserID: "@preview-contact:shadowchat.local",
                remoteUserID: "preview-contact",
                displayName: "Vorschau-Kontakt",
                isOwnedByCurrentUser: false,
                lastSeenAt: Date()
            )
        ]
    }
}
