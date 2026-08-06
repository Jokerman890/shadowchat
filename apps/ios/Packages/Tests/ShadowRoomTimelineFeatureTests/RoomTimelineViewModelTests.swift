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
                        securityState: .encrypted,
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
        XCTAssertEqual(viewModel.securityState, .encrypted)
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

    func testObserveTimelineAppliesStreamedSnapshot() async {
        let updatedItem = RoomTimelineItemViewState(
            messageId: "streamed-message",
            senderDisplayName: "Ari",
            body: "Live update",
            sentAtLabel: "10:05",
            direction: .incoming,
            deliveryState: .delivered
        )
        let repository = StreamingRoomTimelineRepository(
            updatedSnapshot: RoomTimelineSnapshotViewState(
                roomId: "stream-room",
                roomTitle: "Live Room",
                securityState: .unencrypted,
                items: [updatedItem]
            )
        )
        let viewModel = RoomTimelineViewModel(
            roomId: "stream-room",
            repository: repository
        )

        await viewModel.observeTimeline()

        XCTAssertEqual(
            viewModel.state,
            .loaded(roomTitle: "Live Room", items: [updatedItem])
        )
        XCTAssertEqual(viewModel.securityState, .unencrypted)
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

    func testSendReliesOnTimelineEchoAndClearsDraft() async {
        let viewModel = RoomTimelineViewModel(
            roomId: "room-send",
            repository: SendingRoomTimelineRepository()
        )
        await viewModel.load()
        viewModel.send(.draftChanged("Hello ShadowChat"))

        await viewModel.sendDraft()

        guard case let .loaded(_, items) = viewModel.state else {
            return XCTFail("Expected a loaded timeline")
        }
        XCTAssertEqual(items.map(\.messageId), ["existing-message"])
        XCTAssertEqual(viewModel.draft, "")
        XCTAssertNil(viewModel.sendErrorMessage)
    }

    func testUnavailableSendPreservesDraftAndPublishesError() async {
        let viewModel = RoomTimelineViewModel(
            roomId: "room-no-send",
            repository: StubRoomTimelineRepository(
                result: .success(
                    RoomTimelineSnapshotViewState(
                        roomId: "room-no-send",
                        roomTitle: "Read only",
                        items: [
                            RoomTimelineItemViewState(
                                messageId: "existing",
                                senderDisplayName: "Ari",
                                body: "Existing",
                                sentAtLabel: "10:00",
                                direction: .incoming,
                                deliveryState: .read
                            )
                        ]
                    )
                )
            )
        )
        await viewModel.load()
        viewModel.send(.draftChanged("Keep me"))

        await viewModel.sendDraft()

        XCTAssertEqual(viewModel.draft, "Keep me")
        XCTAssertNotNil(viewModel.sendErrorMessage)
    }

    func testSendFromEmptyRoomClearsDraftWithoutSyntheticMessage() async {
        let viewModel = RoomTimelineViewModel(
            roomId: "empty-room",
            repository: EmptySendingRoomTimelineRepository()
        )
        await viewModel.load()
        viewModel.send(.draftChanged("First message"))

        await viewModel.sendDraft()

        XCTAssertEqual(viewModel.state, .empty(roomTitle: "Empty room"))
        XCTAssertEqual(viewModel.draft, "")
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

private struct StreamingRoomTimelineRepository: RoomTimelineRepository {
    let updatedSnapshot: RoomTimelineSnapshotViewState

    func loadTimeline(roomId: String) async throws -> RoomTimelineSnapshotViewState {
        RoomTimelineSnapshotViewState(
            roomId: roomId,
            roomTitle: "Live Room",
            securityState: .unknown,
            items: []
        )
    }

    func timelineUpdates(
        roomId: String
    ) async throws -> AsyncStream<RoomTimelineSnapshotViewState> {
        AsyncStream { continuation in
            continuation.yield(updatedSnapshot)
            continuation.finish()
        }
    }
}

private struct SendingRoomTimelineRepository: RoomTimelineRepository {
    func loadTimeline(roomId: String) async throws -> RoomTimelineSnapshotViewState {
        RoomTimelineSnapshotViewState(
            roomId: roomId,
            roomTitle: "Send Test",
            items: [
                RoomTimelineItemViewState(
                    messageId: "existing-message",
                    senderDisplayName: "Ari",
                    body: "Ready",
                    sentAtLabel: "Earlier",
                    direction: .incoming,
                    deliveryState: .read
                )
            ]
        )
    }

    func sendMessage(roomId: String, body: String) async throws {}
}

private struct EmptySendingRoomTimelineRepository: RoomTimelineRepository {
    func loadTimeline(roomId: String) async throws -> RoomTimelineSnapshotViewState {
        RoomTimelineSnapshotViewState(
            roomId: roomId,
            roomTitle: "Empty room",
            items: []
        )
    }

    func sendMessage(roomId: String, body: String) async throws {}
}
