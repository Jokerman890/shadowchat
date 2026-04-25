import Foundation
import ShadowDesignSystem

public struct ChatListItemViewState: Equatable, Identifiable, Sendable {
    public let roomId: String
    public let title: String
    public let unreadCount: Int
    public let trustLevel: ChatListTrustLevel

    public var id: String { roomId }

    public init(
        roomId: String,
        title: String,
        unreadCount: Int,
        trustLevel: ChatListTrustLevel
    ) {
        self.roomId = roomId
        self.title = title
        self.unreadCount = unreadCount
        self.trustLevel = trustLevel
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
