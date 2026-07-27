import Foundation
import MatrixRustSDK
import ShadowChatListFeature
import ShadowCoreContracts
import ShadowRoomTimelineFeature

struct MatrixTimelineContext {
    let timeline: Timeline
    var observationToken: TaskHandle?
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
        let roomTitle = try await roomInfo(roomID: roomID).displayName
        return RoomTimelineSnapshotViewState(
            roomId: roomID,
            roomTitle: roomTitle,
            items: context.items.compactMap(makeTimelineItem)
        )
    }

    func sendMessage(
        roomID: String,
        body: String
    ) async throws -> RoomTimelineItemViewState {
        let normalizedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedBody.isEmpty else {
            throw RoomTimelineRepositoryError.sendingUnavailable
        }

        do {
            let context = try await timelineContext(roomID: roomID)
            let content = messageEventContentFromMarkdown(md: normalizedBody)
            _ = try await context.timeline.send(msg: content)
            return makeSentTimelineItem(body: normalizedBody)
        } catch {
            throw mapError(error)
        }
    }

    func resetTimelines() {
        timelines.values.forEach { $0.observationToken?.cancel() }
        timelines.removeAll()
    }

    private func timelineContext(roomID: String) async throws -> MatrixTimelineContext {
        if let context = timelines[roomID] {
            return context
        }

        guard let client,
              let room = try client.getRoom(roomId: roomID) else {
            throw ShadowServiceError.unknown("Der Matrix-Raum wurde nicht gefunden.")
        }

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
        timelines[roomID] = MatrixTimelineContext(
            timeline: timeline,
            observationToken: nil,
            items: [],
            receivedInitialUpdate: false
        )

        let listener = MatrixTimelineListener { [weak self] diffs in
            Task {
                await self?.applyTimelineDiffs(diffs, roomID: roomID)
            }
        }
        timelines[roomID]?.observationToken = await timeline.addListener(listener: listener)

        for _ in 0..<100 where timelines[roomID]?.receivedInitialUpdate == false {
            try await Task.sleep(for: .milliseconds(10))
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
        context.receivedInitialUpdate = true
        timelines[roomID] = context
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

    private func makeSentTimelineItem(body: String) -> RoomTimelineItemViewState {
        RoomTimelineItemViewState(
            messageId: UUID().uuidString,
            senderDisplayName: sessionSnapshot.account?.displayName,
            body: body,
            sentAtLabel: Date().formatted(date: .omitted, time: .shortened),
            direction: .outgoing,
            deliveryState: .sent
        )
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
