import XCTest
@testable import ShadowChatListFeature

@MainActor
final class ChatListViewModelTests: XCTestCase {
    func testLoadPublishesLoadedState() async {
        let item = ChatListItemViewState(
            roomId: "room-1",
            title: "General",
            unreadCount: 3,
            trustLevel: .verified
        )
        let viewModel = ChatListViewModel(repository: StubChatListRepository(result: .success([item])))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded(items: [item]))
    }

    func testLoadPublishesEmptyState() async {
        let viewModel = ChatListViewModel(repository: StubChatListRepository(result: .success([])))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .empty)
    }

    func testLoadPublishesFailedState() async {
        let viewModel = ChatListViewModel(repository: StubChatListRepository(result: .failure(TestError())))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed)
    }

    func testRetryReloadsItems() async {
        let repository = SequencedChatListRepository(results: [
            .failure(TestError()),
            .success([
                ChatListItemViewState(
                    roomId: "room-2",
                    title: "Recovered",
                    unreadCount: 0,
                    trustLevel: .standard
                )
            ])
        ])
        let viewModel = ChatListViewModel(repository: repository)

        await viewModel.load()
        XCTAssertEqual(viewModel.state, .failed)

        await viewModel.load()
        XCTAssertEqual(
            viewModel.state,
            .loaded(items: [
                ChatListItemViewState(
                    roomId: "room-2",
                    title: "Recovered",
                    unreadCount: 0,
                    trustLevel: .standard
                )
            ])
        )
    }

    func testRoomSelectionIsRaised() {
        var selectedRoomId: String?
        let viewModel = ChatListViewModel(
            repository: StubChatListRepository(result: .success([])),
            onRoomSelected: { selectedRoomId = $0 }
        )

        viewModel.send(.roomSelected(roomId: "room-3"))

        XCTAssertEqual(selectedRoomId, "room-3")
    }
}

private struct StubChatListRepository: ChatListRepository {
    let result: Result<[ChatListItemViewState], Error>

    func loadChatList() async throws -> [ChatListItemViewState] {
        try result.get()
    }
}

private final class SequencedChatListRepository: ChatListRepository, @unchecked Sendable {
    private var results: [Result<[ChatListItemViewState], Error>]

    init(results: [Result<[ChatListItemViewState], Error>]) {
        self.results = results
    }

    func loadChatList() async throws -> [ChatListItemViewState] {
        guard !results.isEmpty else { return [] }
        return try results.removeFirst().get()
    }
}

private struct TestError: Error {}
