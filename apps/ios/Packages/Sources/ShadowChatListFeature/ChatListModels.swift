import Foundation
import ShadowDesignSystem

public struct ChatListItemViewState: Equatable, Identifiable, Sendable {
    public let roomId: String
    public let title: String
    public let previewText: String
    public let sentAtLabel: String
    public let unreadCount: Int
    public let trustLevel: ChatListTrustLevel
    public let isFavorite: Bool

    public var id: String { roomId }

    public init(
        roomId: String,
        title: String,
        previewText: String = "",
        sentAtLabel: String = "",
        unreadCount: Int,
        trustLevel: ChatListTrustLevel,
        isFavorite: Bool = false
    ) {
        self.roomId = roomId
        self.title = title
        self.previewText = previewText
        self.sentAtLabel = sentAtLabel
        self.unreadCount = unreadCount
        self.trustLevel = trustLevel
        self.isFavorite = isFavorite
    }
}

public struct ChatListRoomSummaryViewState: Equatable, Sendable {
    public let roomId: String
    public let displayName: String
    public let lastMessagePreview: String
    public let lastMessageSentAtLabel: String
    public let unreadCount: Int
    public let trustLevel: ChatListTrustLevel
    public let membership: ChatListMembership
    public let isFavorite: Bool
    public let hasUnreadMentions: Bool

    public init(
        roomId: String,
        displayName: String,
        lastMessagePreview: String = "",
        lastMessageSentAtLabel: String = "",
        unreadCount: Int,
        trustLevel: ChatListTrustLevel,
        membership: ChatListMembership,
        isFavorite: Bool = false,
        hasUnreadMentions: Bool = false
    ) {
        self.roomId = roomId
        self.displayName = displayName
        self.lastMessagePreview = lastMessagePreview
        self.lastMessageSentAtLabel = lastMessageSentAtLabel
        self.unreadCount = unreadCount
        self.trustLevel = trustLevel
        self.membership = membership
        self.isFavorite = isFavorite
        self.hasUnreadMentions = hasUnreadMentions
    }

    public func asChatListItemViewState() -> ChatListItemViewState {
        ChatListItemViewState(
            roomId: roomId,
            title: displayName,
            previewText: lastMessagePreview,
            sentAtLabel: lastMessageSentAtLabel,
            unreadCount: unreadCount,
            trustLevel: trustLevel,
            isFavorite: isFavorite
        )
    }
}

public enum ChatListTrustLevel: Equatable, Sendable {
    case verified
    case standard
    case reduced

    public var designTone: ShadowTrustTone {
        switch self {
        case .verified:
            return .verified
        case .standard:
            return .standard
        case .reduced:
            return .reduced
        }
    }
}

public enum ChatListMembership: Equatable, Sendable {
    case joined
    case invited
    case left
    case knocked
    case banned
}

public enum ChatListState: Equatable, Sendable {
    case loading
    case loaded(items: [ChatListItemViewState])
    case empty
    case failed
}

public enum ChatListEvent: Equatable, Sendable {
    case appeared
    case refreshRequested
    case retryRequested
    case roomSelected(roomId: String)
}
