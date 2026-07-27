import Foundation

public struct RoomTimelineProjectionInput<Identifier> {
    public let identifier: Identifier
    public let senderDisplayName: String?
    public let body: String
    public let timestampMilliseconds: UInt64
    public let direction: RoomTimelineMessageDirection
    public let sendState: RoomTimelineProjectionSendState

    public init(
        identifier: Identifier,
        senderDisplayName: String?,
        body: String,
        timestampMilliseconds: UInt64,
        direction: RoomTimelineMessageDirection,
        sendState: RoomTimelineProjectionSendState
    ) {
        self.identifier = identifier
        self.senderDisplayName = senderDisplayName
        self.body = body
        self.timestampMilliseconds = timestampMilliseconds
        self.direction = direction
        self.sendState = sendState
    }
}

public enum RoomTimelineProjectionSendState: Sendable {
    case notSentYet
    case sendingFailed
    case sent
    case remote
}

public enum RoomTimelineProjection {
    public static func map<Input, Output>(
        _ items: [Input],
        transform: (Input) -> Output?
    ) -> [Output] {
        items.compactMap(transform)
    }

    public static func makeItem<Identifier>(
        _ input: RoomTimelineProjectionInput<Identifier>
    ) -> RoomTimelineItemViewState {
        let date = Date(
            timeIntervalSince1970: TimeInterval(input.timestampMilliseconds) / 1_000
        )
        return RoomTimelineItemViewState(
            messageId: String(describing: input.identifier),
            senderDisplayName: input.senderDisplayName,
            body: input.body,
            sentAtLabel: date.formatted(date: .omitted, time: .shortened),
            direction: input.direction,
            deliveryState: deliveryState(for: input.sendState)
        )
    }

    private static func deliveryState(
        for sendState: RoomTimelineProjectionSendState
    ) -> RoomTimelineDeliveryState {
        switch sendState {
        case .notSentYet:
            .sending
        case .sendingFailed:
            .failed
        case .sent:
            .sent
        case .remote:
            .delivered
        }
    }
}

public enum RoomTimelineCollectionReducer {
    public static func append<Element>(
        _ appended: [Element],
        to items: inout [Element]
    ) {
        items.append(contentsOf: appended)
    }

    public static func clear<Element>(_ items: inout [Element]) {
        items.removeAll()
    }

    public static func insert<Element>(
        _ item: Element,
        at index: Int,
        in items: inout [Element]
    ) {
        items.insert(item, at: max(0, min(index, items.count)))
    }

    public static func reset<Element>(
        _ replacement: [Element],
        in items: inout [Element]
    ) {
        items = replacement
    }

    public static func set<Element>(
        _ item: Element,
        at index: Int,
        in items: inout [Element]
    ) {
        guard items.indices.contains(index) else {
            return
        }
        items[index] = item
    }

    public static func truncate<Element>(
        _ items: inout [Element],
        to length: Int
    ) {
        items = Array(items.prefix(max(0, length)))
    }

    public static func popBack<Element>(_ items: inout [Element]) {
        if !items.isEmpty {
            items.removeLast()
        }
    }

    public static func popFront<Element>(_ items: inout [Element]) {
        if !items.isEmpty {
            items.removeFirst()
        }
    }

    public static func pushBack<Element>(
        _ item: Element,
        to items: inout [Element]
    ) {
        items.append(item)
    }

    public static func pushFront<Element>(
        _ item: Element,
        to items: inout [Element]
    ) {
        items.insert(item, at: 0)
    }

    public static func remove<Element>(
        at index: Int,
        from items: inout [Element]
    ) {
        guard items.indices.contains(index) else {
            return
        }
        items.remove(at: index)
    }
}
