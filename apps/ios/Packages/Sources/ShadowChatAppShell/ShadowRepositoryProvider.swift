import ShadowChatListFeature
import ShadowRoomTimelineFeature

public protocol ShadowRepositoryProvider: Sendable {
    func makeChatListRepository() -> ChatListRepository
    func makeRoomTimelineRepository(roomId: String) -> RoomTimelineRepository
}

struct DemoShadowRepositoryProvider: ShadowRepositoryProvider {
    func makeChatListRepository() -> ChatListRepository {
        DemoChatListRepository()
    }

    func makeRoomTimelineRepository(roomId: String) -> RoomTimelineRepository {
        DemoRoomTimelineRepository()
    }
}
