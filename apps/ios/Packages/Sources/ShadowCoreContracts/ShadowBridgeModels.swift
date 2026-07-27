import Foundation

public enum ShadowBridgeKind: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case matrix
    case whatsApp
    case signal

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .matrix:
            "Matrix"
        case .whatsApp:
            "WhatsApp"
        case .signal:
            "Signal"
        }
    }

    public var implementationName: String {
        switch self {
        case .matrix:
            "Matrix Rust SDK"
        case .whatsApp:
            "mautrix-whatsapp"
        case .signal:
            "mautrix-signal"
        }
    }
}

public enum ShadowBridgeConnectionState: String, Codable, CaseIterable, Sendable {
    case unavailable
    case notConfigured
    case pairing
    case connected
    case degraded
    case reconnecting
    case failed

    public var isOperational: Bool {
        self == .connected || self == .degraded
    }
}

public enum ShadowBridgeTrust: String, Codable, CaseIterable, Sendable {
    case nativeEncrypted
    case externalEncryptedTransport
    case reduced

    public var title: String {
        switch self {
        case .nativeEncrypted:
            "Nativ Ende-zu-Ende verschlüsselt"
        case .externalEncryptedTransport:
            "Externer verschlüsselter Transport"
        case .reduced:
            "Reduzierter Vertrauenskontext"
        }
    }
}

public enum ShadowBridgeCapability: String, Codable, CaseIterable, Hashable, Sendable {
    case text
    case media
    case reactions
    case replies
    case readReceipts
    case typing
    case voiceMessages
    case calls
    case disappearingMessages
}

public struct ShadowBridgeSnapshot: Codable, Equatable, Identifiable, Sendable {
    public var id: ShadowBridgeKind { kind }

    public let kind: ShadowBridgeKind
    public let state: ShadowBridgeConnectionState
    public let trust: ShadowBridgeTrust
    public let accountLabel: String?
    public let capabilities: Set<ShadowBridgeCapability>
    public let lastSyncAt: Date?
    public let warning: String?

    public init(
        kind: ShadowBridgeKind,
        state: ShadowBridgeConnectionState,
        trust: ShadowBridgeTrust,
        accountLabel: String? = nil,
        capabilities: Set<ShadowBridgeCapability>,
        lastSyncAt: Date? = nil,
        warning: String? = nil
    ) {
        self.kind = kind
        self.state = state
        self.trust = trust
        self.accountLabel = accountLabel
        self.capabilities = capabilities
        self.lastSyncAt = lastSyncAt
        self.warning = warning
    }
}

public enum ShadowPairingState: String, Codable, CaseIterable, Sendable {
    case requesting
    case ready
    case scanned
    case confirming
    case paired
    case expired
    case cancelled
    case failed

    public var isTerminal: Bool {
        switch self {
        case .paired, .expired, .cancelled, .failed:
            true
        default:
            false
        }
    }
}

public struct ShadowPairingSession: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let bridge: ShadowBridgeKind
    public let state: ShadowPairingState
    public let payload: String
    public let qrCodeData: Data?
    public let deviceName: String
    public let createdAt: Date
    public let expiresAt: Date

    public init(
        id: UUID = UUID(),
        bridge: ShadowBridgeKind,
        state: ShadowPairingState,
        payload: String,
        qrCodeData: Data? = nil,
        deviceName: String,
        createdAt: Date = Date(),
        expiresAt: Date
    ) {
        self.id = id
        self.bridge = bridge
        self.state = state
        self.payload = payload
        self.qrCodeData = qrCodeData
        self.deviceName = deviceName
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }

    public func remainingLifetime(at date: Date = Date()) -> TimeInterval {
        max(0, expiresAt.timeIntervalSince(date))
    }
}

public struct ShadowUserPuppet: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let bridge: ShadowBridgeKind
    public let matrixUserID: String
    public let remoteUserID: String
    public let displayName: String
    public let isOwnedByCurrentUser: Bool
    public let lastSeenAt: Date?

    public init(
        id: String,
        bridge: ShadowBridgeKind,
        matrixUserID: String,
        remoteUserID: String,
        displayName: String,
        isOwnedByCurrentUser: Bool,
        lastSeenAt: Date? = nil
    ) {
        self.id = id
        self.bridge = bridge
        self.matrixUserID = matrixUserID
        self.remoteUserID = remoteUserID
        self.displayName = displayName
        self.isOwnedByCurrentUser = isOwnedByCurrentUser
        self.lastSeenAt = lastSeenAt
    }
}
