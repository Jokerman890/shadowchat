import Foundation

public struct RoomTimelineSnapshotViewState: Equatable, Sendable {
    public let roomId: String
    public let roomTitle: String?
    public let securityState: RoomTimelineSecurityState
    public let items: [RoomTimelineItemViewState]

    public init(
        roomId: String,
        roomTitle: String?,
        securityState: RoomTimelineSecurityState = .unknown,
        items: [RoomTimelineItemViewState]
    ) {
        self.roomId = roomId
        self.roomTitle = roomTitle
        self.securityState = securityState
        self.items = items
    }
}

public enum RoomTimelineSecurityState: Equatable, Sendable {
    case encrypted
    case unencrypted
    case unknown
}

public struct RoomTimelineItemViewState: Equatable, Identifiable, Sendable {
    public let messageId: String
    public let senderDisplayName: String?
    public let body: String
    public let sentAtLabel: String
    public let direction: RoomTimelineMessageDirection
    public let deliveryState: RoomTimelineDeliveryState

    public var id: String { messageId }

    public init(
        messageId: String,
        senderDisplayName: String?,
        body: String,
        sentAtLabel: String,
        direction: RoomTimelineMessageDirection,
        deliveryState: RoomTimelineDeliveryState
    ) {
        self.messageId = messageId
        self.senderDisplayName = senderDisplayName
        self.body = body
        self.sentAtLabel = sentAtLabel
        self.direction = direction
        self.deliveryState = deliveryState
    }
}

public enum RoomTimelineMessageDirection: Equatable, Sendable {
    case incoming
    case outgoing
}

public enum RoomTimelineDeliveryState: Equatable, Sendable {
    case sending
    case sent
    case delivered
    case read
    case failed
}

public enum RoomTimelineState: Equatable, Sendable {
    case loading
    case loaded(roomTitle: String?, items: [RoomTimelineItemViewState])
    case empty(roomTitle: String?)
    case failed
}

public enum RoomTimelineEvent: Equatable, Sendable {
    case refreshRequested
    case retryRequested
    case draftChanged(String)
    case sendRequested
}
