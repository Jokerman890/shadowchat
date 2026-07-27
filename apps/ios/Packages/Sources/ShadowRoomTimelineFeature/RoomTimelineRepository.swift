public protocol RoomTimelineRepository: Sendable {
    func loadTimeline(roomId: String) async throws -> RoomTimelineSnapshotViewState
    func sendMessage(roomId: String, body: String) async throws -> RoomTimelineItemViewState
}

public enum RoomTimelineRepositoryError: Error, Equatable, Sendable {
    case sendingUnavailable
}

public extension RoomTimelineRepository {
    func sendMessage(roomId: String, body: String) async throws -> RoomTimelineItemViewState {
        throw RoomTimelineRepositoryError.sendingUnavailable
    }
}
