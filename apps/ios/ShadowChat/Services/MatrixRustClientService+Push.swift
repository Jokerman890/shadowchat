import Foundation
import MatrixRustSDK
import ShadowCoreContracts

extension MatrixRustClientService {
    func registerPush(
        deviceToken: Data,
        gatewayURL: URL
    ) async throws -> ShadowPushRegistration {
        guard let client else {
            throw ShadowServiceError.sessionExpired
        }
        guard gatewayURL.scheme?.lowercased() == "https" else {
            throw ShadowServiceError.pushConfigurationMissing
        }

        let identifiers = PusherIdentifiers(
            pushkey: deviceToken.base64EncodedString(),
            appId: "de.shadowchat.ios"
        )
        let persistedIdentifiers = MatrixPersistedPusherIdentifiers(
            pushKey: deviceToken.base64EncodedString(),
            appID: "de.shadowchat.ios"
        )
        let payload = ShadowAPNSPayload(
            clientIdentifier: UUID().uuidString
        )
        var pusherWasRegistered = false

        do {
            let payloadData = try JSONEncoder().encode(payload)
            guard let payloadJSON = String(
                data: payloadData,
                encoding: .utf8
            ) else {
                throw ShadowServiceError.pushConfigurationMissing
            }

            try await client.setPusher(
                identifiers: identifiers,
                kind: .http(
                    data: .init(
                        url: gatewayURL.absoluteString,
                        format: .eventIdOnly,
                        defaultPayload: payloadJSON
                    )
                ),
                appDisplayName: "ShadowChat (iOS)",
                deviceDisplayName: "ShadowChat for iOS",
                profileTag: nil,
                lang: Locale.current.language.languageCode?.identifier ?? "de",
                append: false
            )
            pusherWasRegistered = true

            guard let activeToken else {
                throw MatrixSessionPersistenceError.missingSession
            }
            let updatedToken = activeToken.updating(
                pusherIdentifiers: persistedIdentifiers
            )
            try keychain.save(updatedToken)
            self.activeToken = updatedToken
            registeredPushIdentifiers = identifiers
            return ShadowPushRegistration(
                state: .registered,
                registeredAt: Date()
            )
        } catch {
            if pusherWasRegistered {
                try? await client.deletePusher(identifiers: identifiers)
            }
            registeredPushIdentifiers = nil
            throw mapError(error)
        }
    }

    func unregisterPush() async throws {
        guard let identifiers = registeredPushIdentifiers
            ?? activeToken?.pusherIdentifiers?.sdkValue else {
            return
        }
        guard let client else {
            throw ShadowServiceError.sessionExpired
        }

        do {
            try await client.deletePusher(identifiers: identifiers)
            registeredPushIdentifiers = nil
            if let activeToken {
                let updatedToken = activeToken.updating(pusherIdentifiers: nil)
                self.activeToken = updatedToken
                try keychain.save(updatedToken)
            }
        } catch {
            throw mapError(error)
        }
    }
}

private struct ShadowAPNSPayload: Encodable {
    let aps = ShadowAPS()
    let clientIdentifier: String

    enum CodingKeys: String, CodingKey {
        case aps
        case clientIdentifier = "client_id"
    }
}

private struct ShadowAPS: Encodable {
    let mutableContent = 1
    let alert = ShadowAPSAlert()

    enum CodingKeys: String, CodingKey {
        case mutableContent = "mutable-content"
        case alert
    }
}

private struct ShadowAPSAlert: Encodable {
    let localizationKey = "Notification"

    enum CodingKeys: String, CodingKey {
        case localizationKey = "loc-key"
    }
}
