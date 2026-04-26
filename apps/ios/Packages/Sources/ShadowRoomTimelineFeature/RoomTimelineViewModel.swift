import Combine
import Foundation

@MainActor
public final class RoomTimelineViewModel: ObservableObject {
    @Published public private(set) var state: RoomTimelineState

    private let roomId: String
    private let repository: RoomTimelineRepository

    public init(
        roomId: String,
        repository: RoomTimelineRepository,
        initialState: RoomTimelineState = .loading
    ) {
        self.roomId = roomId
        self.repository = repository
        self.state = initialState
    }

    public func send(_ event: RoomTimelineEvent) {
        switch event {
        case .appeared:
            guard state == .loading else { return }
            Task { await load() }
        case .refreshRequested, .retryRequested:
            Task { await load() }
        }
    }

    public func load() async {
        state = .loading

        do {
            let snapshot = try await repository.loadTimeline(roomId: roomId)
            if snapshot.items.isEmpty {
                state = .empty(roomTitle: snapshot.roomTitle)
            } else {
                state = .loaded(roomTitle: snapshot.roomTitle, items: snapshot.items)
            }
        } catch {
            state = .failed
        }
    }
}
