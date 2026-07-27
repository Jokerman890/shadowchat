import Foundation
import MatrixRustSDK
import ShadowCoreContracts

actor MatrixRustClientService: ShadowClientService {
    nonisolated let runtimeEnvironment = ShadowRuntimeEnvironment.matrix

    private let keychain: MatrixSessionKeychain
    var client: Client?
    private var syncService: SyncService?
    private var activeToken: MatrixRestorationToken?
    var sessionSnapshot: ShadowSessionSnapshot
    var timelines: [String: MatrixTimelineContext] = [:]

    init(keychain: MatrixSessionKeychain = MatrixSessionKeychain()) {
        self.keychain = keychain
        sessionSnapshot = ShadowSessionSnapshot(
            state: .signedOut,
            environment: .matrix
        )
    }

    func restoreSession() async throws -> ShadowSessionSnapshot? {
        guard let token = try keychain.activeToken() else {
            return nil
        }

        do {
            try ensureDirectoriesExist(token.directories)

            let restoredClient = try await ClientBuilder()
                .setSessionDelegate(sessionDelegate: keychain)
                .sqliteStore(
                    config: .init(
                        dataPath: token.directories.dataPath,
                        cachePath: token.directories.cachePath
                    )
                    .passphrase(passphrase: token.storePassphrase)
                )
                .withSearchIndexStore(
                    path: token.directories.dataPath,
                    password: token.storePassphrase
                )
                .username(username: token.session.userId)
                .homeserverUrl(url: token.session.homeserverUrl)
                .build()

            try await restoredClient.restoreSession(session: token.session)
            client = restoredClient
            activeToken = token
            sessionSnapshot = try makeSessionSnapshot(
                client: restoredClient,
                state: .active,
                lastSyncAt: nil
            )
            return sessionSnapshot
        } catch {
            client = nil
            activeToken = nil
            throw mapError(error)
        }
    }

    func signIn(_ request: ShadowLoginRequest) async throws -> ShadowSessionSnapshot {
        guard request.homeserver.scheme?.lowercased() == "https",
              request.homeserver.host != nil else {
            throw ShadowServiceError.invalidHomeserver
        }

        let username = request.username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !username.isEmpty, !request.password.isEmpty else {
            throw ShadowServiceError.invalidCredentials
        }

        let directories = try MatrixSessionDirectories.create()
        let passphrase = try SecurePassphraseGenerator.make()

        do {
            let authenticatedClient = try await makeAuthenticationClient(
                homeserver: request.homeserver,
                directories: directories,
                passphrase: passphrase
            )

            try await authenticatedClient.login(
                username: username,
                password: request.password,
                initialDeviceName: request.deviceDisplayName,
                deviceId: nil
            )

            let sdkSession = try authenticatedClient.session()
            let token = MatrixRestorationToken(
                session: sdkSession,
                directories: directories,
                storePassphrase: passphrase
            )
            try keychain.save(token)

            client = authenticatedClient
            activeToken = token
            sessionSnapshot = try makeSessionSnapshot(
                client: authenticatedClient,
                state: .active,
                lastSyncAt: nil
            )
            return sessionSnapshot
        } catch {
            try? directories.remove()
            throw mapError(error)
        }
    }

    private func makeAuthenticationClient(
        homeserver: URL,
        directories: MatrixSessionDirectories,
        passphrase: String
    ) async throws -> Client {
        try await ClientBuilder()
            .setSessionDelegate(sessionDelegate: keychain)
            .slidingSyncVersionBuilder(versionBuilder: .discoverNative)
            .autoEnableCrossSigning(autoEnableCrossSigning: true)
            .autoEnableBackups(autoEnableBackups: true)
            .backupDownloadStrategy(backupDownloadStrategy: .afterDecryptionFailure)
            .enableShareHistoryOnInvite(enableShareHistoryOnInvite: true)
            .sqliteStore(
                config: .init(
                    dataPath: directories.dataPath,
                    cachePath: directories.cachePath
                )
                .passphrase(passphrase: passphrase)
            )
            .serverNameOrHomeserverUrl(serverNameOrUrl: homeserver.absoluteString)
            .build()
    }

    func currentSession() async -> ShadowSessionSnapshot {
        sessionSnapshot
    }

    func startSync() async throws -> ShadowSessionSnapshot {
        guard let client, sessionSnapshot.state.grantsMessagingAccess else {
            throw ShadowServiceError.sessionExpired
        }

        do {
            let service: SyncService
            if let syncService {
                service = syncService
            } else {
                service = try await client
                    .syncService()
                    .withOfflineMode()
                    .withSharePos(enable: true)
                    .finish()
                syncService = service
            }

            await service.start()
            let syncedAt = Date()
            sessionSnapshot = try makeSessionSnapshot(
                client: client,
                state: .syncing,
                lastSyncAt: syncedAt
            )
            return sessionSnapshot
        } catch {
            throw mapError(error)
        }
    }

    func stopSync() async {
        await syncService?.stop()
        syncService = nil
        resetTimelines()

        if sessionSnapshot.state.grantsMessagingAccess {
            sessionSnapshot = ShadowSessionSnapshot(
                state: .active,
                account: sessionSnapshot.account,
                capabilities: sessionSnapshot.capabilities,
                lastSyncAt: sessionSnapshot.lastSyncAt,
                environment: .matrix
            )
        }
    }

    func signOut(eraseLocalData: Bool) async throws -> ShadowSessionSnapshot {
        await stopSync()

        do {
            try await client?.logout()
        } catch {
            if !eraseLocalData {
                throw mapError(error)
            }
        }

        client = nil
        if eraseLocalData {
            try keychain.removeActiveToken()
            try activeToken?.directories.remove()
        }
        activeToken = nil
        sessionSnapshot = ShadowSessionSnapshot(
            state: .signedOut,
            environment: .matrix
        )
        return sessionSnapshot
    }

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

    private func makeSessionSnapshot(
        client: Client,
        state: ShadowSessionState,
        lastSyncAt: Date?
    ) throws -> ShadowSessionSnapshot {
        let userID = try client.userId()
        let deviceID = try client.deviceId()
        let session = try client.session()
        guard let homeserver = URL(string: session.homeserverUrl) else {
            throw ShadowServiceError.invalidHomeserver
        }

        let displayName = userID
            .trimmingCharacters(in: CharacterSet(charactersIn: "@"))
            .split(separator: ":")
            .first
            .map(String.init) ?? userID
        let account = ShadowAccount(
            id: userID,
            userID: userID,
            displayName: displayName,
            homeserver: homeserver,
            deviceID: deviceID
        )
        return ShadowSessionSnapshot(
            state: state,
            account: account,
            capabilities: Set(ShadowSessionCapability.allCases),
            lastSyncAt: lastSyncAt,
            environment: .matrix
        )
    }

    private func ensureDirectoriesExist(_ directories: MatrixSessionDirectories) throws {
        try FileManager.default.createDirectory(
            at: directories.dataDirectory,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: directories.cacheDirectory,
            withIntermediateDirectories: true
        )
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

    func mapError(_ error: any Error) -> ShadowServiceError {
        if let error = error as? ShadowServiceError {
            return error
        }

        let message = String(describing: error)
        let normalized = message.lowercased()
        if normalized.contains("forbidden")
            || normalized.contains("unauthorized")
            || normalized.contains("credentials") {
            return .invalidCredentials
        }
        if normalized.contains("network")
            || normalized.contains("connection")
            || normalized.contains("timed out") {
            return .networkUnavailable
        }
        if normalized.contains("discovery")
            || normalized.contains("well-known")
            || normalized.contains("homeserver") {
            return .serverDiscoveryFailed
        }
        return .unknown(message)
    }
}
