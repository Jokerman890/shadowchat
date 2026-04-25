import Combine
import Foundation

@MainActor
public final class ChatListViewModel: ObservableObject {
    @Published public private(set) var state: ChatListState

    private let repository: ChatListRepository
    private let onRoomSelected: @MainActor (String) -> Void

    public init(
        repository: ChatListRepository,
        initialState: ChatListState = .loading,
        onRoomSelected: @escaping @MainActor (String) -> Void = { _ in }
    ) {
        self.repository = repository
        self.state = initialState
        self.onRoomSelected = onRoomSelected
    }

    public func send(_ event: ChatListEvent) {
        switch event {
        case .appeared:
            guard state == .loading else { return }
            Task { await load() }
        case .refreshRequested, .retryRequested:
            Task { await load() }
        case let .roomSelected(roomId):
            onRoomSelected(roomId)
        }
    }

    public func load() async {
        state = .loading

        do {
            let items = try await repository.loadChatList()
            state = items.isEmpty ? .empty : .loaded(items: items)
        } catch {
            state = .failed
        }
    }
}
