import Foundation
import MatrixRustSDK
import ShadowChatListFeature
import ShadowCoreContracts
import ShadowRoomTimelineFeature

actor MatrixRustClientService: ShadowClientService {
    nonisolated let runtimeEnvironment = ShadowRuntimeEnvironment.matrix

    private struct TimelineContext {
        let timeline: Timeline
        var observationToken: TaskHandle?
        var items: [TimelineItem]
        var receivedInitialUpdate: Bool
    }

    private let keychain: MatrixSessionKeychain
    private var client: Client?
    private var syncService: SyncService?
    private var activeToken: MatrixRestorationToken?
    private var sessionSnapshot: ShadowSessionSnapshot
    private var timelines: [String: TimelineContext] = [:]

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
            let authenticatedClient = try await ClientBuilder()
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
                .serverNameOrHomeserverUrl(
                    serverNameOrUrl: request.homeserver.absoluteString
                )
                .build()

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
        timelines.values.forEach { $0.observationToken?.cancel() }
        timelines.removeAll()

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

    func loadChatList() async throws -> [ChatListItemViewState] {
        guard let client else {
            throw ShadowServiceError.sessionExpired
        }

        do {
            var rooms: [ChatListItemViewState] = []
            for room in client.rooms() {
                let info = try room.roomInfo()
                guard info.membership == .joined, !info.isSpace else {
                    continue
                }

                let title = info.displayName?.nonEmpty
                    ?? info.canonicalAlias?.nonEmpty
                    ?? info.id
                let unreadCount = Int(clamping: info.numUnreadMessages)
                let encrypted = info.encryptionState == .encrypted

                rooms.append(
                    ChatListItemViewState(
                        roomId: info.id,
                        title: title,
                        previewText: encrypted
                            ? "Ende-zu-Ende verschlüsselter Matrix-Raum"
                            : "Matrix-Raum ohne Ende-zu-Ende-Verschlüsselung",
                        unreadCount: unreadCount,
                        trustLevel: encrypted ? .standard : .reduced,
                        isFavorite: info.isFavourite
                    )
                )
            }

            return rooms.sorted {
                if $0.isFavorite != $1.isFavorite {
                    return $0.isFavorite
                }
                if $0.unreadCount != $1.unreadCount {
                    return $0.unreadCount > $1.unreadCount
                }
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        } catch {
            throw mapError(error)
        }
    }

    func loadTimeline(roomID: String) async throws -> RoomTimelineSnapshotViewState {
        let context = try await timelineContext(roomID: roomID)
        let roomTitle = try roomInfo(roomID: roomID).displayName
        return RoomTimelineSnapshotViewState(
            roomId: roomID,
            roomTitle: roomTitle,
            items: context.items.compactMap(makeTimelineItem)
        )
    }

    func sendMessage(
        roomID: String,
        body: String
    ) async throws -> RoomTimelineItemViewState {
        let normalizedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedBody.isEmpty else {
            throw RoomTimelineRepositoryError.sendingUnavailable
        }

        do {
            let context = try await timelineContext(roomID: roomID)
            let content = messageEventContentFromMarkdown(md: normalizedBody)
            _ = try await context.timeline.send(msg: content)
            return RoomTimelineItemViewState(
                messageId: UUID().uuidString,
                senderDisplayName: sessionSnapshot.account?.displayName,
                body: normalizedBody,
                sentAtLabel: Date().formatted(date: .omitted, time: .shortened),
                direction: .outgoing,
                deliveryState: .sent
            )
        } catch {
            throw mapError(error)
        }
    }

    private func timelineContext(roomID: String) async throws -> TimelineContext {
        if let context = timelines[roomID] {
            return context
        }

        guard let client,
              let room = try client.getRoom(roomId: roomID) else {
            throw ShadowServiceError.unknown("Der Matrix-Raum wurde nicht gefunden.")
        }

        let timeline = try await room.timelineWithConfiguration(
            configuration: .init(
                focus: .live(hideThreadedEvents: false),
                filter: .all,
                internalIdPrefix: nil,
                dateDividerMode: .daily,
                trackReadReceipts: .messageLikeEvents,
                reportUtds: true
            )
        )
        timelines[roomID] = TimelineContext(
            timeline: timeline,
            observationToken: nil,
            items: [],
            receivedInitialUpdate: false
        )

        let listener = MatrixTimelineListener { [weak self] diffs in
            Task {
                await self?.applyTimelineDiffs(diffs, roomID: roomID)
            }
        }
        let token = await timeline.addListener(listener: listener)
        timelines[roomID]?.observationToken = token

        for _ in 0..<100 where timelines[roomID]?.receivedInitialUpdate == false {
            try await Task.sleep(for: .milliseconds(10))
        }

        guard let context = timelines[roomID] else {
            throw ShadowServiceError.unknown("Die Matrix-Timeline konnte nicht geöffnet werden.")
        }
        return context
    }

    private func applyTimelineDiffs(_ diffs: [TimelineDiff], roomID: String) {
        guard var context = timelines[roomID] else {
            return
        }

        for diff in diffs {
            switch diff {
            case .append(let items):
                context.items.append(contentsOf: items)
            case .clear:
                context.items.removeAll()
            case .insert(let index, let item):
                context.items.insert(item, at: min(Int(index), context.items.count))
            case .popBack:
                if !context.items.isEmpty {
                    context.items.removeLast()
                }
            case .popFront:
                if !context.items.isEmpty {
                    context.items.removeFirst()
                }
            case .pushBack(let item):
                context.items.append(item)
            case .pushFront(let item):
                context.items.insert(item, at: 0)
            case .remove(let index):
                if context.items.indices.contains(Int(index)) {
                    context.items.remove(at: Int(index))
                }
            case .reset(let items):
                context.items = Array(items)
            case .set(let index, let item):
                if context.items.indices.contains(Int(index)) {
                    context.items[Int(index)] = item
                }
            case .truncate(let length):
                context.items = Array(context.items.prefix(Int(length)))
            }
        }
        context.receivedInitialUpdate = true
        timelines[roomID] = context
    }

    private func makeTimelineItem(_ item: TimelineItem) -> RoomTimelineItemViewState? {
        guard let event = item.asEvent(),
              case .msgLike(let messageLike) = event.content,
              case .message(let message) = messageLike.kind else {
            return nil
        }

        let deliveryState: RoomTimelineDeliveryState
        switch event.localSendState {
        case .notSentYet:
            deliveryState = .sending
        case .sendingFailed:
            deliveryState = .failed
        case .sent:
            deliveryState = .sent
        case nil:
            deliveryState = .delivered
        }

        let date = Date(timeIntervalSince1970: TimeInterval(event.timestamp) / 1_000)
        return RoomTimelineItemViewState(
            messageId: String(describing: item.uniqueId()),
            senderDisplayName: event.isOwn ? sessionSnapshot.account?.displayName : event.sender,
            body: message.body,
            sentAtLabel: date.formatted(date: .omitted, time: .shortened),
            direction: event.isOwn ? .outgoing : .incoming,
            deliveryState: deliveryState
        )
    }

    private func roomInfo(roomID: String) throws -> RoomInfo {
        guard let client,
              let room = try client.getRoom(roomId: roomID) else {
            throw ShadowServiceError.unknown("Der Matrix-Raum wurde nicht gefunden.")
        }
        return try room.roomInfo()
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

    private func mapError(_ error: any Error) -> ShadowServiceError {
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

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
