import ShadowChatListFeature
import ShadowRoomTimelineFeature

protocol ShadowRepositoryProvider {
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
