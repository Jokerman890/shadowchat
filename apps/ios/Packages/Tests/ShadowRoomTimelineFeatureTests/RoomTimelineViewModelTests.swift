import XCTest
@testable import ShadowRoomTimelineFeature

@MainActor
final class RoomTimelineViewModelTests: XCTestCase {
    func testLoadPublishesLoadedState() async {
        let item = RoomTimelineItemViewState(
            messageId: "message-1",
            senderDisplayName: "Ari",
            body: "Hello",
            sentAtLabel: "09:41",
            direction: .incoming,
            deliveryState: .read
        )
        let viewModel = RoomTimelineViewModel(
            roomId: "room-1",
            repository: StubRoomTimelineRepository(
                result: .success(
                    RoomTimelineSnapshotViewState(
                        roomId: "room-1",
                        roomTitle: "General",
                        items: [item]
                    )
                )
            )
        )

        await viewModel.load()

        XCTAssertEqual(
            viewModel.state,
            .loaded(roomTitle: "General", items: [item])
        )
    }

    func testLoadPublishesEmptyState() async {
        let viewModel = RoomTimelineViewModel(
            roomId: "room-2",
            repository: StubRoomTimelineRepository(
                result: .success(
                    RoomTimelineSnapshotViewState(
                        roomId: "room-2",
                        roomTitle: "Quiet Room",
                        items: []
                    )
                )
            )
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .empty(roomTitle: "Quiet Room"))
    }

    func testLoadPublishesFailedState() async {
        let viewModel = RoomTimelineViewModel(
            roomId: "room-3",
            repository: StubRoomTimelineRepository(result: .failure(TestError()))
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed)
    }

    func testRetryReloadsItems() async {
        let item = RoomTimelineItemViewState(
            messageId: "message-2",
            senderDisplayName: nil,
            body: "Recovered",
            sentAtLabel: "10:00",
            direction: .outgoing,
            deliveryState: .sent
        )
        let repository = SequencedRoomTimelineRepository(results: [
            .failure(TestError()),
            .success(
                RoomTimelineSnapshotViewState(
                    roomId: "room-4",
                    roomTitle: "Recovered Room",
                    items: [item]
                )
            )
        ])
        let viewModel = RoomTimelineViewModel(roomId: "room-4", repository: repository)

        await viewModel.load()
        XCTAssertEqual(viewModel.state, .failed)

        await viewModel.load()
        XCTAssertEqual(
            viewModel.state,
            .loaded(roomTitle: "Recovered Room", items: [item])
        )
    }
}

private struct StubRoomTimelineRepository: RoomTimelineRepository {
    let result: Result<RoomTimelineSnapshotViewState, Error>

    func loadTimeline(roomId: String) async throws -> RoomTimelineSnapshotViewState {
        try result.get()
    }
}

private final class SequencedRoomTimelineRepository: RoomTimelineRepository, @unchecked Sendable {
    private var results: [Result<RoomTimelineSnapshotViewState, Error>]

    init(results: [Result<RoomTimelineSnapshotViewState, Error>]) {
        self.results = results
    }

    func loadTimeline(roomId: String) async throws -> RoomTimelineSnapshotViewState {
        guard !results.isEmpty else {
            return RoomTimelineSnapshotViewState(roomId: roomId, roomTitle: nil, items: [])
        }
        return try results.removeFirst().get()
    }
}

private struct TestError: Error {}
