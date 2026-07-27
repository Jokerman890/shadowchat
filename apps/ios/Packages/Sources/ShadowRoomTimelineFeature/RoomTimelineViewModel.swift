import Combine
import Foundation

@MainActor
public final class RoomTimelineViewModel: ObservableObject {
    @Published public private(set) var state: RoomTimelineState
    @Published public private(set) var securityState: RoomTimelineSecurityState = .unknown
    @Published public private(set) var draft = ""
    @Published public private(set) var isSending = false
    @Published public private(set) var sendErrorMessage: String?

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
        case .refreshRequested, .retryRequested:
            Task { await load() }
        case .draftChanged(let draft):
            self.draft = draft
            sendErrorMessage = nil
        case .sendRequested:
            Task { await sendDraft() }
        }
    }

    public func load() async {
        state = .loading

        do {
            apply(try await repository.loadTimeline(roomId: roomId))
        } catch {
            state = .failed
        }
    }

    public func observeTimeline() async {
        state = .loading

        do {
            apply(try await repository.loadTimeline(roomId: roomId))
            let updates = try await repository.timelineUpdates(roomId: roomId)
            for await snapshot in updates {
                try Task.checkCancellation()
                apply(snapshot)
            }
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed
        }
    }

    public func sendDraft() async {
        guard !isSending else { return }
        let body = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }

        switch state {
        case .loaded, .empty:
            break
        case .loading, .failed:
            sendErrorMessage = "Nachrichten können erst nach dem Laden des Raums gesendet werden."
            return
        }

        isSending = true
        sendErrorMessage = nil
        defer { isSending = false }

        do {
            try await repository.sendMessage(roomId: roomId, body: body)
            draft = ""
        } catch RoomTimelineRepositoryError.sendingUnavailable {
            sendErrorMessage = "Für diesen Raum ist noch keine Send-Pipeline verbunden."
        } catch {
            sendErrorMessage = "Die Nachricht konnte nicht gesendet werden."
        }
    }

    private func apply(_ snapshot: RoomTimelineSnapshotViewState) {
        securityState = snapshot.securityState
        if snapshot.items.isEmpty {
            state = .empty(roomTitle: snapshot.roomTitle)
        } else {
            state = .loaded(roomTitle: snapshot.roomTitle, items: snapshot.items)
        }
    }
}
