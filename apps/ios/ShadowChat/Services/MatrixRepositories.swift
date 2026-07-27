import OSLog
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
        let interval = ShadowPerformanceSignposts.repository.beginInterval("RoomListLoad")
        defer {
            ShadowPerformanceSignposts.repository.endInterval("RoomListLoad", interval)
        }

        return try await service.loadChatList()
    }
}

private struct MatrixRoomTimelineRepository: RoomTimelineRepository {
    let service: MatrixRustClientService

    func loadTimeline(roomId: String) async throws -> RoomTimelineSnapshotViewState {
        let interval = ShadowPerformanceSignposts.repository.beginInterval("TimelineLoad")
        defer {
            ShadowPerformanceSignposts.repository.endInterval("TimelineLoad", interval)
        }

        return try await service.loadTimeline(roomID: roomId)
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
        let interval = ShadowPerformanceSignposts.repository.beginInterval("MessageSend")
        defer {
            ShadowPerformanceSignposts.repository.endInterval("MessageSend", interval)
        }

        try await service.sendMessage(roomID: roomId, body: body)
    }
}
