import Foundation

public enum ShadowRuntimeEnvironment: String, Codable, Sendable {
    case matrix
    case localPreview
}

public enum ShadowAuthenticationMode: String, Codable, Sendable {
    case oauth
    case password
    case unsupported
}

public struct ShadowAuthenticationDiscovery: Codable, Equatable, Sendable {
    public let homeserver: URL
    public let mode: ShadowAuthenticationMode
    public let supportsAccountCreation: Bool

    public init(
        homeserver: URL,
        mode: ShadowAuthenticationMode,
        supportsAccountCreation: Bool
    ) {
        self.homeserver = homeserver
        self.mode = mode
        self.supportsAccountCreation = supportsAccountCreation
    }
}

public struct ShadowOAuthAuthorization: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let authorizationURL: URL
    public let callbackScheme: String

    public init(
        id: UUID = UUID(),
        authorizationURL: URL,
        callbackScheme: String
    ) {
        self.id = id
        self.authorizationURL = authorizationURL
        self.callbackScheme = callbackScheme
    }
}

public enum ShadowSessionState: String, Codable, CaseIterable, Sendable {
    case launching
    case signedOut
    case discovering
    case authenticating
    case restoring
    case active
    case syncing
    case offline
    case expired
    case locked
    case failed

    public var grantsMessagingAccess: Bool {
        switch self {
        case .active, .syncing, .offline:
            true
        default:
            false
        }
    }
}

public enum ShadowSessionCapability: String, Codable, CaseIterable, Hashable, Sendable {
    case roomList
    case timeline
    case send
    case media
    case push
    case encryption
}

public struct ShadowAccount: Codable, Equatable, Hashable, Identifiable, Sendable {
    public let id: String
    public let userID: String
    public let displayName: String
    public let homeserver: URL
    public let deviceID: String

    public init(
        id: String,
        userID: String,
        displayName: String,
        homeserver: URL,
        deviceID: String
    ) {
        self.id = id
        self.userID = userID
        self.displayName = displayName
        self.homeserver = homeserver
        self.deviceID = deviceID
    }
}

public struct ShadowSessionSnapshot: Codable, Equatable, Sendable {
    public let state: ShadowSessionState
    public let account: ShadowAccount?
    public let capabilities: Set<ShadowSessionCapability>
    public let lastSyncAt: Date?
    public let environment: ShadowRuntimeEnvironment

    public init(
        state: ShadowSessionState,
        account: ShadowAccount? = nil,
        capabilities: Set<ShadowSessionCapability> = [],
        lastSyncAt: Date? = nil,
        environment: ShadowRuntimeEnvironment
    ) {
        self.state = state
        self.account = account
        self.capabilities = capabilities
        self.lastSyncAt = lastSyncAt
        self.environment = environment
    }

    public static let signedOutPreview = ShadowSessionSnapshot(
        state: .signedOut,
        environment: .localPreview
    )
}

public struct ShadowLoginRequest: Equatable, Sendable {
    public let homeserver: URL
    public let username: String
    public let password: String
    public let deviceDisplayName: String

    public init(
        homeserver: URL,
        username: String,
        password: String,
        deviceDisplayName: String
    ) {
        self.homeserver = homeserver
        self.username = username
        self.password = password
        self.deviceDisplayName = deviceDisplayName
    }
}

public enum ShadowServiceError: LocalizedError, Equatable, Sendable {
    case invalidHomeserver
    case invalidCredentials
    case networkUnavailable
    case serverDiscoveryFailed
    case sessionExpired
    case deviceUntrusted
    case cryptoUnavailable
    case unsupportedOperation
    case pairingExpired
    case bridgeUnavailable
    case cancelled
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .invalidHomeserver:
            "Die Homeserver-Adresse ist ungültig."
        case .invalidCredentials:
            "Benutzername oder Passwort wurden abgelehnt."
        case .networkUnavailable:
            "ShadowChat kann das Netzwerk nicht erreichen."
        case .serverDiscoveryFailed:
            "Der Matrix-Homeserver konnte nicht erkannt werden."
        case .sessionExpired:
            "Die Sitzung ist abgelaufen. Bitte melde dich erneut an."
        case .deviceUntrusted:
            "Dieses Gerät ist noch nicht verifiziert."
        case .cryptoUnavailable:
            "Der verschlüsselte Nachrichtenspeicher ist nicht verfügbar."
        case .unsupportedOperation:
            "Dieser Vorgang wird von der aktuellen Verbindung nicht unterstützt."
        case .pairingExpired:
            "Der Kopplungscode ist abgelaufen."
        case .bridgeUnavailable:
            "Die Bridge ist derzeit nicht erreichbar."
        case .cancelled:
            "Der Vorgang wurde abgebrochen."
        case .unknown(let message):
            message
        }
    }
}
