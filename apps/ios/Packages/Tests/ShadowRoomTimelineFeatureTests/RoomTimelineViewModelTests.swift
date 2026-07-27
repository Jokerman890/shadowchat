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

    func testSendAppendsMessageAndClearsDraft() async {
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
        XCTAssertEqual(items.last?.body, "Hello ShadowChat")
        XCTAssertEqual(items.last?.deliveryState, .sent)
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

    func testSendCreatesFirstMessageInEmptyRoom() async {
        let viewModel = RoomTimelineViewModel(
            roomId: "empty-room",
            repository: EmptySendingRoomTimelineRepository()
        )
        await viewModel.load()
        viewModel.send(.draftChanged("First message"))

        await viewModel.sendDraft()

        guard case let .loaded(roomTitle, items) = viewModel.state else {
            return XCTFail("Expected the empty room to become loaded")
        }
        XCTAssertEqual(roomTitle, "Empty room")
        XCTAssertEqual(items.map(\.body), ["First message"])
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

    func sendMessage(roomId: String, body: String) async throws -> RoomTimelineItemViewState {
        RoomTimelineItemViewState(
            messageId: "sent-message",
            senderDisplayName: nil,
            body: body,
            sentAtLabel: "Now",
            direction: .outgoing,
            deliveryState: .sent
        )
    }
}

private struct EmptySendingRoomTimelineRepository: RoomTimelineRepository {
    func loadTimeline(roomId: String) async throws -> RoomTimelineSnapshotViewState {
        RoomTimelineSnapshotViewState(
            roomId: roomId,
            roomTitle: "Empty room",
            items: []
        )
    }

    func sendMessage(roomId: String, body: String) async throws -> RoomTimelineItemViewState {
        RoomTimelineItemViewState(
            messageId: "first-message",
            senderDisplayName: nil,
            body: body,
            sentAtLabel: "Now",
            direction: .outgoing,
            deliveryState: .sent
        )
    }
}
