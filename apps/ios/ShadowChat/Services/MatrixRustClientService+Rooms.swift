import Foundation
import MatrixRustSDK
import ShadowChatListFeature
import ShadowCoreContracts
import ShadowRoomTimelineFeature

struct MatrixTimelineContext {
    let timeline: Timeline
    let roomTitle: String?
    let securityState: RoomTimelineSecurityState
    var observationToken: TaskHandle?
    var initialUpdateContinuation: AsyncStream<Void>.Continuation?
    var items: [TimelineItem]
    var receivedInitialUpdate: Bool
}

extension MatrixRustClientService {
    func loadChatList() async throws -> [ChatListItemViewState] {
        guard let client else {
            throw ShadowServiceError.sessionExpired
        }

        do {
            var rooms: [ChatListItemViewState] = []
            for room in client.rooms() {
                let info = try await room.roomInfo()
                guard info.membership == .joined, !info.isSpace else {
                    continue
                }
                rooms.append(makeChatListItem(info))
            }
            return rooms.sorted(by: chatListSort)
        } catch {
            throw mapError(error)
        }
    }

    func loadTimeline(roomID: String) async throws -> RoomTimelineSnapshotViewState {
        let context = try await timelineContext(roomID: roomID)
        return makeTimelineSnapshot(roomID: roomID, context: context)
    }

    func timelineUpdates(
        roomID: String
    ) async throws -> AsyncStream<RoomTimelineSnapshotViewState> {
        let context = try await timelineContext(roomID: roomID)
        let subscriberID = UUID()
        let (stream, continuation) = AsyncStream.makeStream(
            of: RoomTimelineSnapshotViewState.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        continuation.onTermination = { [weak self] _ in
            Task {
                await self?.removeTimelineContinuation(
                    roomID: roomID,
                    subscriberID: subscriberID
                )
            }
        }
        timelineContinuations[roomID, default: [:]][subscriberID] = continuation
        continuation.yield(makeTimelineSnapshot(roomID: roomID, context: context))
        return stream
    }

    func sendMessage(
        roomID: String,
        body: String
    ) async throws {
        let normalizedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedBody.isEmpty else {
            throw RoomTimelineRepositoryError.sendingUnavailable
        }

        do {
            let context = try await timelineContext(roomID: roomID)
            let content = messageEventContentFromMarkdown(md: normalizedBody)
            _ = try await context.timeline.send(msg: content)
        } catch {
            throw mapError(error)
        }
    }

    func resetTimelines() {
        timelines.values.forEach {
            $0.observationToken?.cancel()
            $0.initialUpdateContinuation?.finish()
        }
        timelineContinuations.values
            .flatMap(\.values)
            .forEach { $0.finish() }
        timelineContinuations.removeAll()
        timelines.removeAll()
    }

    func timelineContext(roomID: String) async throws -> MatrixTimelineContext {
        if let context = timelines[roomID] {
            return context
        }

        guard let client,
              let room = try client.getRoom(roomId: roomID) else {
            throw ShadowServiceError.unknown("Der Matrix-Raum wurde nicht gefunden.")
        }

        let info = try await room.roomInfo()
        let timeline = try await room.timelineWithConfiguration(
            configuration: .init(
                focus: .live(hideThreadedEvents: false),
                filter: .all,
                internalIdPrefix: nil,
                dateDividerMode: .daily,
                trackReadReceipts: .messageLikeEvents,
                reportUtds: true
            )
        )
        let (initialUpdateStream, initialUpdateContinuation) = AsyncStream.makeStream(
            of: Void.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        timelines[roomID] = MatrixTimelineContext(
            timeline: timeline,
            roomTitle: info.displayName?.nonEmpty
                ?? info.canonicalAlias?.nonEmpty
                ?? info.id,
            securityState: info.encryptionState == .encrypted
                ? .encrypted
                : .unencrypted,
            observationToken: nil,
            initialUpdateContinuation: initialUpdateContinuation,
            items: [],
            receivedInitialUpdate: false
        )

        let listener = MatrixTimelineListener { [weak self] diffs in
            Task {
                await self?.applyTimelineDiffs(diffs, roomID: roomID)
            }
        }
        timelines[roomID]?.observationToken = await timeline.addListener(listener: listener)

        do {
            try await waitForInitialTimelineUpdate(initialUpdateStream)
        } catch {
            timelines[roomID]?.observationToken?.cancel()
            timelines[roomID]?.initialUpdateContinuation?.finish()
            timelines[roomID] = nil
            throw error
        }

        guard let context = timelines[roomID] else {
            throw ShadowServiceError.unknown("Die Matrix-Timeline konnte nicht geöffnet werden.")
        }
        return context
    }

    private func applyTimelineDiffs(_ diffs: [TimelineDiff], roomID: String) {
        guard var context = timelines[roomID] else {
            return
        }
        for diff in diffs {
            apply(diff, to: &context.items)
        }
        if !context.receivedInitialUpdate {
            context.receivedInitialUpdate = true
            context.initialUpdateContinuation?.yield(())
            context.initialUpdateContinuation?.finish()
            context.initialUpdateContinuation = nil
        }
        timelines[roomID] = context
        let snapshot = makeTimelineSnapshot(roomID: roomID, context: context)
        timelineContinuations[roomID]?.values.forEach {
            $0.yield(snapshot)
        }
    }

    private func waitForInitialTimelineUpdate(
        _ stream: AsyncStream<Void>
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                var iterator = stream.makeAsyncIterator()
                guard await iterator.next() != nil else {
                    throw CancellationError()
                }
            }
            group.addTask {
                try await Task.sleep(for: .seconds(10))
                throw ShadowServiceError.unknown(
                    "Die Matrix-Timeline hat kein initiales Update geliefert."
                )
            }
            _ = try await group.next()
            group.cancelAll()
        }
    }

    private func removeTimelineContinuation(
        roomID: String,
        subscriberID: UUID
    ) {
        timelineContinuations[roomID]?[subscriberID] = nil
        guard timelineContinuations[roomID]?.isEmpty == true else {
            return
        }
        timelineContinuations[roomID] = nil
        timelines[roomID]?.observationToken?.cancel()
        timelines[roomID]?.initialUpdateContinuation?.finish()
        timelines[roomID] = nil
    }

    private func makeTimelineSnapshot(
        roomID: String,
        context: MatrixTimelineContext
    ) -> RoomTimelineSnapshotViewState {
        RoomTimelineSnapshotViewState(
            roomId: roomID,
            roomTitle: context.roomTitle,
            securityState: context.securityState,
            items: context.items.compactMap(makeTimelineItem)
        )
    }

    private func apply(_ diff: TimelineDiff, to items: inout [TimelineItem]) {
        switch diff {
        case .append, .clear, .insert, .reset, .set, .truncate:
            applyCollectionChange(diff, to: &items)
        case .popBack, .popFront, .pushBack, .pushFront, .remove:
            applyEdgeChange(diff, to: &items)
        }
    }

    private func applyCollectionChange(
        _ diff: TimelineDiff,
        to items: inout [TimelineItem]
    ) {
        switch diff {
        case .append(let appended):
            items.append(contentsOf: appended)
        case .clear:
            items.removeAll()
        case .insert(let index, let item):
            items.insert(item, at: min(Int(index), items.count))
        case .reset(let replacement):
            items = Array(replacement)
        case .set(let index, let item):
            replace(item, at: Int(index), in: &items)
        case .truncate(let length):
            items = Array(items.prefix(Int(length)))
        default:
            return
        }
    }

    private func applyEdgeChange(
        _ diff: TimelineDiff,
        to items: inout [TimelineItem]
    ) {
        switch diff {
        case .popBack:
            if !items.isEmpty {
                items.removeLast()
            }
        case .popFront:
            if !items.isEmpty {
                items.removeFirst()
            }
        case .pushBack(let item):
            items.append(item)
        case .pushFront(let item):
            items.insert(item, at: 0)
        case .remove(let index):
            removeItem(at: Int(index), from: &items)
        default:
            return
        }
    }

    private func replace(
        _ item: TimelineItem,
        at index: Int,
        in items: inout [TimelineItem]
    ) {
        guard items.indices.contains(index) else {
            return
        }
        items[index] = item
    }

    private func removeItem(at index: Int, from items: inout [TimelineItem]) {
        guard items.indices.contains(index) else {
            return
        }
        items.remove(at: index)
    }

    private func makeChatListItem(_ info: RoomInfo) -> ChatListItemViewState {
        let title = info.displayName?.nonEmpty
            ?? info.canonicalAlias?.nonEmpty
            ?? info.id
        let encrypted = info.encryptionState == .encrypted
        return ChatListItemViewState(
            roomId: info.id,
            title: title,
            previewText: encrypted
                ? "Ende-zu-Ende verschlüsselter Matrix-Raum"
                : "Matrix-Raum ohne Ende-zu-Ende-Verschlüsselung",
            unreadCount: Int(clamping: info.numUnreadMessages),
            trustLevel: encrypted ? .standard : .reduced,
            isFavorite: info.isFavourite
        )
    }

    private func chatListSort(
        _ first: ChatListItemViewState,
        _ second: ChatListItemViewState
    ) -> Bool {
        if first.isFavorite != second.isFavorite {
            return first.isFavorite
        }
        if first.unreadCount != second.unreadCount {
            return first.unreadCount > second.unreadCount
        }
        return first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
    }

    private func makeTimelineItem(_ item: TimelineItem) -> RoomTimelineItemViewState? {
        guard let event = item.asEvent(),
              case .msgLike(let messageLike) = event.content,
              case .message(let message) = messageLike.kind else {
            return nil
        }

        let date = Date(timeIntervalSince1970: TimeInterval(event.timestamp) / 1_000)
        return RoomTimelineItemViewState(
            messageId: String(describing: item.uniqueId()),
            senderDisplayName: event.isOwn ? sessionSnapshot.account?.displayName : event.sender,
            body: message.body,
            sentAtLabel: date.formatted(date: .omitted, time: .shortened),
            direction: event.isOwn ? .outgoing : .incoming,
            deliveryState: deliveryState(for: event)
        )
    }

    private func deliveryState(
        for event: EventTimelineItem
    ) -> RoomTimelineDeliveryState {
        switch event.localSendState {
        case .notSentYet:
            .sending
        case .sendingFailed:
            .failed
        case .sent:
            .sent
        case nil:
            .delivered
        }
    }

    private func roomInfo(roomID: String) async throws -> RoomInfo {
        guard let client,
              let room = try client.getRoom(roomId: roomID) else {
            throw ShadowServiceError.unknown("Der Matrix-Raum wurde nicht gefunden.")
        }
        return try await room.roomInfo()
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
