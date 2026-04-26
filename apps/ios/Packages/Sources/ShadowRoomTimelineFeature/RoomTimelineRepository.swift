public protocol RoomTimelineRepository: Sendable {
    func loadTimeline(roomId: String) async throws -> RoomTimelineSnapshotViewState
}
