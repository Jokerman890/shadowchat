import XCTest
@testable import ShadowChatListFeature

final class ChatListRoomSummaryMappingTests: XCTestCase {
    func testRoomSummaryMapsToChatListItemViewState() {
        let summary = ChatListRoomSummaryViewState(
            roomId: "sofia",
            displayName: "Sofia Martin",
            lastMessagePreview: "Dinner is still on.",
            lastMessageSentAtLabel: "09:41",
            unreadCount: 2,
            trustLevel: .verified,
            membership: .joined,
            isFavorite: true,
            hasUnreadMentions: false
        )

        let item = summary.asChatListItemViewState()

        XCTAssertEqual(item.roomId, "sofia")
        XCTAssertEqual(item.title, "Sofia Martin")
        XCTAssertEqual(item.previewText, "Dinner is still on.")
        XCTAssertEqual(item.sentAtLabel, "09:41")
        XCTAssertEqual(item.unreadCount, 2)
        XCTAssertEqual(item.trustLevel, .verified)
        XCTAssertTrue(item.isFavorite)
    }
}
