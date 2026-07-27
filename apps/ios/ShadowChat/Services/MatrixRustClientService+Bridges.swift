import Foundation
import MatrixRustSDK
import ShadowCoreContracts

struct MatrixBridgePairingContext {
    let bridge: ShadowBridgeKind
    let managementRoomID: String
    let botUserID: String
    let confirmationStartedAt: Date
    let expiresAt: Date
}

private struct MatrixBridgeConfiguration {
    let managementRoomID: String
    let botUserID: String
    let loginCommand: String
    let capabilities: Set<ShadowBridgeCapability>

    static func configured(for bridge: ShadowBridgeKind) -> Self? {
        let roomKey: String
        let botKey: String
        let command: String
        let capabilities: Set<ShadowBridgeCapability>

        switch bridge {
        case .matrix:
            return nil
        case .whatsApp:
            roomKey = "ShadowWhatsAppManagementRoomID"
            botKey = "ShadowWhatsAppBotUserID"
            command = "login qr"
            capabilities = [
                .text,
                .media,
                .reactions,
                .replies,
                .readReceipts,
                .typing,
                .voiceMessages
            ]
        case .signal:
            roomKey = "ShadowSignalManagementRoomID"
            botKey = "ShadowSignalBotUserID"
            command = "login"
            capabilities = [
                .text,
                .media,
                .reactions,
                .replies,
                .readReceipts,
                .typing,
                .voiceMessages,
                .disappearingMessages
            ]
        }

        guard let roomID = Bundle.main.object(
            forInfoDictionaryKey: roomKey
        ) as? String,
        !roomID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        let botUserID = Bundle.main.object(
            forInfoDictionaryKey: botKey
        ) as? String,
        !botUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return MatrixBridgeConfiguration(
            managementRoomID: roomID,
            botUserID: botUserID,
            loginCommand: command,
            capabilities: capabilities
        )
    }
}

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
        guard let configuration = MatrixBridgeConfiguration.configured(
            for: bridge
        ) else {
            throw ShadowServiceError.bridgeUnavailable
        }
        guard sessionSnapshot.state.grantsMessagingAccess else {
            throw ShadowServiceError.sessionExpired
        }

        let startedAt = Date()
        bridgeStates[bridge] = .pairing

        do {
            try await sendBridgeCommand(
                configuration.loginCommand,
                roomID: configuration.managementRoomID
            )
            let response = try await waitForPairingResponse(
                roomID: configuration.managementRoomID,
                expectedBotUserID: configuration.botUserID,
                after: startedAt
            )
            let expiresAt = Date().addingTimeInterval(60)
            let pairing = ShadowPairingSession(
                bridge: bridge,
                state: .ready,
                payload: response.payload,
                qrCodeData: response.qrCodeData,
                deviceName: deviceName,
                createdAt: startedAt,
                expiresAt: expiresAt
            )
            pendingBridgePairings[pairing.id] = MatrixBridgePairingContext(
                bridge: bridge,
                managementRoomID: configuration.managementRoomID,
                botUserID: configuration.botUserID,
                confirmationStartedAt: Date(),
                expiresAt: expiresAt
            )
            return pairing
        } catch {
            bridgeStates[bridge] = .failed
            throw mapError(error)
        }
    }

    func confirmPairing(sessionID: UUID) async throws -> ShadowBridgeSnapshot {
        guard let context = pendingBridgePairings[sessionID],
              context.expiresAt > Date(),
              let configuration = MatrixBridgeConfiguration.configured(
                  for: context.bridge
              ),
              configuration.managementRoomID == context.managementRoomID,
              configuration.botUserID == context.botUserID else {
            throw ShadowServiceError.pairingExpired
        }

        do {
            let accountLabel = try await waitForPairingConfirmation(
                roomID: context.managementRoomID,
                expectedBotUserID: context.botUserID,
                after: context.confirmationStartedAt,
                expiresAt: context.expiresAt
            )
            pendingBridgePairings[sessionID] = nil
            bridgeStates[context.bridge] = .connected
            return ShadowBridgeSnapshot(
                kind: context.bridge,
                state: .connected,
                trust: .externalEncryptedTransport,
                accountLabel: accountLabel,
                capabilities: configuration.capabilities,
                lastSyncAt: Date(),
                warning: bridgeWarning
            )
        } catch {
            bridgeStates[context.bridge] = .failed
            throw mapError(error)
        }
    }

    func cancelPairing(sessionID: UUID) async {
        guard let context = pendingBridgePairings.removeValue(
            forKey: sessionID
        ) else {
            return
        }
        try? await sendBridgeCommand(
            "cancel",
            roomID: context.managementRoomID
        )
        bridgeStates[context.bridge] = .notConfigured
    }

    func disconnectBridge(
        _ bridge: ShadowBridgeKind,
        revokeRemoteSession: Bool
    ) async throws -> ShadowBridgeSnapshot {
        guard bridge != .matrix,
              let configuration = MatrixBridgeConfiguration.configured(
                  for: bridge
              ) else {
            throw ShadowServiceError.bridgeUnavailable
        }

        do {
            try await sendBridgeCommand(
                "logout",
                roomID: configuration.managementRoomID
            )
            bridgeStates[bridge] = .notConfigured
            return externalBridgeSnapshot(kind: bridge)
        } catch {
            bridgeStates[bridge] = .failed
            throw mapError(error)
        }
    }

    func puppets(for bridge: ShadowBridgeKind) async throws
        -> [ShadowUserPuppet] {
        guard bridge == .matrix
                || MatrixBridgeConfiguration.configured(for: bridge) != nil
        else {
            throw ShadowServiceError.bridgeUnavailable
        }
        return []
    }

    private func externalBridgeSnapshot(
        kind: ShadowBridgeKind
    ) -> ShadowBridgeSnapshot {
        guard let configuration = MatrixBridgeConfiguration.configured(
            for: kind
        ) else {
            return ShadowBridgeSnapshot(
                kind: kind,
                state: .unavailable,
                trust: .externalEncryptedTransport,
                capabilities: [],
                warning: "\(kind.implementationName) ist für diesen Build nicht konfiguriert."
            )
        }
        return ShadowBridgeSnapshot(
            kind: kind,
            state: bridgeStates[kind] ?? .notConfigured,
            trust: .externalEncryptedTransport,
            capabilities: configuration.capabilities,
            lastSyncAt: sessionSnapshot.lastSyncAt,
            warning: bridgeWarning
        )
    }

    private func sendBridgeCommand(
        _ command: String,
        roomID: String
    ) async throws {
        let context = try await timelineContext(roomID: roomID)
        guard context.securityState == .encrypted else {
            throw ShadowServiceError.bridgeUnavailable
        }
        _ = try await context.timeline.send(
            msg: messageEventContentFromMarkdown(md: command)
        )
    }

    private func waitForPairingResponse(
        roomID: String,
        expectedBotUserID: String,
        after date: Date
    ) async throws -> MatrixBridgePairingResponse {
        for _ in 0..<150 {
            if let response = try await pairingResponse(
                roomID: roomID,
                expectedBotUserID: expectedBotUserID,
                after: date
            ) {
                return response
            }
            try await Task.sleep(for: .milliseconds(200))
        }
        throw ShadowServiceError.pairingExpired
    }

    private func pairingResponse(
        roomID: String,
        expectedBotUserID: String,
        after date: Date
    ) async throws -> MatrixBridgePairingResponse? {
        guard let client else {
            throw ShadowServiceError.sessionExpired
        }
        let context = try await timelineContext(roomID: roomID)

        for item in context.items.reversed() {
            guard let event = item.asEvent(),
                  !event.isOwn,
                  event.sender == expectedBotUserID,
                  Date(
                      timeIntervalSince1970: TimeInterval(event.timestamp) / 1_000
                  ) >= date,
                  case .msgLike(let messageLike) = event.content,
                  case .message(let message) = messageLike.kind else {
                continue
            }

            switch message.msgType {
            case .image(content: let image):
                let data = try await client.getMediaContent(
                    mediaSource: image.source
                )
                return MatrixBridgePairingResponse(
                    payload: "",
                    qrCodeData: data
                )
            case .text(content: let text):
                if let payload = pairingURI(in: text.body) {
                    return MatrixBridgePairingResponse(
                        payload: payload,
                        qrCodeData: nil
                    )
                }
            case .notice(content: let notice):
                if let payload = pairingURI(in: notice.body) {
                    return MatrixBridgePairingResponse(
                        payload: payload,
                        qrCodeData: nil
                    )
                }
            default:
                continue
            }
        }
        return nil
    }

    private func waitForPairingConfirmation(
        roomID: String,
        expectedBotUserID: String,
        after date: Date,
        expiresAt: Date
    ) async throws -> String? {
        while Date() < expiresAt {
            if let confirmation = pairingConfirmation(
                roomID: roomID,
                expectedBotUserID: expectedBotUserID,
                after: date
            ) {
                return confirmation
            }
            try await Task.sleep(for: .milliseconds(200))
        }
        throw ShadowServiceError.pairingExpired
    }

    private func pairingConfirmation(
        roomID: String,
        expectedBotUserID: String,
        after date: Date
    ) -> String? {
        guard let items = timelines[roomID]?.items else { return nil }
        for item in items.reversed() {
            guard let event = item.asEvent(),
                  !event.isOwn,
                  event.sender == expectedBotUserID,
                  Date(
                      timeIntervalSince1970: TimeInterval(event.timestamp) / 1_000
                  ) >= date,
                  case .msgLike(let messageLike) = event.content,
                  case .message(let message) = messageLike.kind else {
                continue
            }
            let body: String?
            switch message.msgType {
            case .text(content: let text):
                body = text.body
            case .notice(content: let notice):
                body = notice.body
            default:
                body = nil
            }
            guard let body, isSuccessfulLogin(body) else { continue }
            return body
        }
        return nil
    }

    private func pairingURI(in body: String) -> String? {
        body.split(whereSeparator: \.isWhitespace)
            .map(String.init)
            .first {
                $0.hasPrefix("sgnl://")
                    || $0.hasPrefix("https://")
            }
    }

    private func isSuccessfulLogin(_ body: String) -> Bool {
        let normalized = body.lowercased()
        return normalized.contains("successfully logged in")
            || normalized.contains("successfully connected")
            || normalized.contains("logged in as")
    }

    private var bridgeWarning: String {
        "Nachrichten durchlaufen einen extern betriebenen Bridge-Dienst."
    }
}

private struct MatrixBridgePairingResponse {
    let payload: String
    let qrCodeData: Data?
}
