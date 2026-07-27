import ShadowChatAppShell
import ShadowChatListFeature
import ShadowRoomTimelineFeature

struct MatrixRepositoryProvider: ShadowRepositoryProvider {
    let service: MatrixRustClientService

    func makeChatListRepository() -> any ChatListRepository {
        MatrixChatListRepository(service: service)
    }

    func makeRoomTimelineRepository(roomId: String) -> any RoomTimelineRepository {
        MatrixRoomTimelineRepository(service: service)
    }
}

private struct MatrixChatListRepository: ChatListRepository {
    let service: MatrixRustClientService

    func loadChatList() async throws -> [ChatListItemViewState] {
        try await service.loadChatList()
    }
}

private struct MatrixRoomTimelineRepository: RoomTimelineRepository {
    let service: MatrixRustClientService

    func loadTimeline(roomId: String) async throws -> RoomTimelineSnapshotViewState {
        try await service.loadTimeline(roomID: roomId)
    }

    func timelineUpdates(
        roomId: String
    ) async throws -> AsyncStream<RoomTimelineSnapshotViewState> {
        try await service.timelineUpdates(roomID: roomId)
    }

    func sendMessage(
        roomId: String,
        body: String
    ) async throws {
        try await service.sendMessage(roomID: roomId, body: body)
    }
}
