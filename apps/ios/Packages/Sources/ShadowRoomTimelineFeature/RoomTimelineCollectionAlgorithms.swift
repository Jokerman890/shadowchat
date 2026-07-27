public enum RoomTimelineProjection {
    public static func map<Input, Output>(
        _ items: [Input],
        transform: (Input) -> Output?
    ) -> [Output] {
        items.compactMap(transform)
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
