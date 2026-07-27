public protocol RoomTimelineRepository: Sendable {
    func loadTimeline(roomId: String) async throws -> RoomTimelineSnapshotViewState
    func timelineUpdates(
        roomId: String
    ) async throws -> AsyncStream<RoomTimelineSnapshotViewState>
    func sendMessage(roomId: String, body: String) async throws
}

public enum RoomTimelineRepositoryError: Error, Equatable, Sendable {
    case sendingUnavailable
}

public extension RoomTimelineRepository {
    func timelineUpdates(
        roomId: String
    ) async throws -> AsyncStream<RoomTimelineSnapshotViewState> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func sendMessage(roomId: String, body: String) async throws {
        throw RoomTimelineRepositoryError.sendingUnavailable
    }
}
