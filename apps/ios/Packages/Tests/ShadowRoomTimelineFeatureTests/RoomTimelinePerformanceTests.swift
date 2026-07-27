import Foundation
import XCTest
@testable import ShadowRoomTimelineFeature

final class RoomTimelinePerformanceTests: XCTestCase {
    func testTimelineMapping100ItemsPerformance() {
        measureMapping(itemCount: 100)
    }

    func testTimelineMapping1_000ItemsPerformance() {
        measureMapping(itemCount: 1_000)
    }

    func testTimelineMapping10_000ItemsPerformance() {
        measureMapping(itemCount: 10_000)
    }

    func testTimelineDiffBurst100ItemsPerformance() {
        measureDiffBurst(itemCount: 100)
    }

    func testTimelineDiffBurst1_000ItemsPerformance() {
        measureDiffBurst(itemCount: 1_000)
    }

    func testTimelineDiffBurst10_000ItemsPerformance() {
        measureDiffBurst(itemCount: 10_000)
    }

    private func measureMapping(itemCount: Int) {
        let fixture = TimelinePerformanceFixture(itemCount: itemCount)
        var mappedItems: [RoomTimelineItemViewState] = []

        measure(
            metrics: [XCTClockMetric()],
            options: measurementOptions
        ) {
            mappedItems = RoomTimelineProjection.map(fixture.mappingItems) { item in
                guard item.shouldInclude else {
                    return nil
                }
                return RoomTimelineItemViewState(
                    messageId: item.messageId,
                    senderDisplayName: item.senderDisplayName,
                    body: item.body,
                    sentAtLabel: item.sentAtLabel,
                    direction: item.direction,
                    deliveryState: item.deliveryState
                )
            }
        }

        XCTAssertEqual(mappedItems.count, fixture.expectedMappedItemCount)
    }

    private func measureDiffBurst(itemCount: Int) {
        let fixture = TimelinePerformanceFixture(itemCount: itemCount)
        var reducedItems: [RoomTimelineItemViewState] = []

        measure(
            metrics: [XCTClockMetric()],
            options: measurementOptions
        ) {
            reducedItems = fixture.baseItems
            fixture.diffBurst.forEach {
                $0.apply(to: &reducedItems)
            }
        }

        XCTAssertEqual(reducedItems, fixture.resetItems)
    }

    private var measurementOptions: XCTMeasureOptions {
        let options = XCTMeasureOptions()
        options.iterationCount = 10
        return options
    }
}

private struct TimelinePerformanceFixture {
    let mappingItems: [TimelineMappingItem]
    let baseItems: [RoomTimelineItemViewState]
    let resetItems: [RoomTimelineItemViewState]
    let diffBurst: [TimelineFixtureDiff]
    let expectedMappedItemCount: Int

    init(itemCount: Int) {
        let mappingFixture = (0..<itemCount).map(TimelineMappingItem.init)
        let baseFixture = (0..<itemCount).map {
            RoomTimelineItemViewState.fixture(index: $0)
        }
        let resetFixture = (itemCount..<(itemCount * 2)).map {
            RoomTimelineItemViewState.fixture(index: $0)
        }

        let mutationCount = min(itemCount, 100)
        var burst: [TimelineFixtureDiff] = []
        burst.reserveCapacity((mutationCount * 7) + 4)
        for offset in 0..<mutationCount {
            let fixtureItem = RoomTimelineItemViewState.fixture(
                index: (itemCount * 2) + offset
            )
            let middleIndex = itemCount / 2
            burst.append(.pushFront(fixtureItem))
            burst.append(.pushBack(fixtureItem))
            burst.append(.insert(index: middleIndex, item: fixtureItem))
            burst.append(.set(index: middleIndex, item: fixtureItem))
            burst.append(.remove(index: middleIndex))
            burst.append(.popFront)
            burst.append(.popBack)
        }
        burst.append(.append(Array(resetFixture.prefix(min(itemCount, 100)))))
        burst.append(.truncate(length: itemCount))
        burst.append(.clear)
        burst.append(.reset(resetFixture))

        mappingItems = mappingFixture
        baseItems = baseFixture
        resetItems = resetFixture
        diffBurst = burst
        expectedMappedItemCount = mappingFixture.lazy.filter(\.shouldInclude).count
    }
}

private struct TimelineMappingItem {
    let messageId: String
    let senderDisplayName: String?
    let body: String
    let sentAtLabel: String
    let direction: RoomTimelineMessageDirection
    let deliveryState: RoomTimelineDeliveryState
    let shouldInclude: Bool

    init(index: Int) {
        messageId = "message-\(index)"
        senderDisplayName = index.isMultiple(of: 2) ? "Ari" : nil
        body = "Deterministic message body \(index)"
        sentAtLabel = String(format: "%02d:%02d", index % 24, index % 60)
        direction = index.isMultiple(of: 2) ? .incoming : .outgoing
        deliveryState = index.isMultiple(of: 3) ? .read : .delivered
        shouldInclude = !index.isMultiple(of: 8)
    }
}

private enum TimelineFixtureDiff {
    case append([RoomTimelineItemViewState])
    case clear
    case insert(index: Int, item: RoomTimelineItemViewState)
    case reset([RoomTimelineItemViewState])
    case set(index: Int, item: RoomTimelineItemViewState)
    case truncate(length: Int)
    case popBack
    case popFront
    case pushBack(RoomTimelineItemViewState)
    case pushFront(RoomTimelineItemViewState)
    case remove(index: Int)

    func apply(to items: inout [RoomTimelineItemViewState]) {
        switch self {
        case .append(let appended):
            RoomTimelineCollectionReducer.append(appended, to: &items)
        case .clear:
            RoomTimelineCollectionReducer.clear(&items)
        case .insert(let index, let item):
            RoomTimelineCollectionReducer.insert(item, at: index, in: &items)
        case .reset(let replacement):
            RoomTimelineCollectionReducer.reset(replacement, in: &items)
        case .set(let index, let item):
            RoomTimelineCollectionReducer.set(item, at: index, in: &items)
        case .truncate(let length):
            RoomTimelineCollectionReducer.truncate(&items, to: length)
        case .popBack:
            RoomTimelineCollectionReducer.popBack(&items)
        case .popFront:
            RoomTimelineCollectionReducer.popFront(&items)
        case .pushBack(let item):
            RoomTimelineCollectionReducer.pushBack(item, to: &items)
        case .pushFront(let item):
            RoomTimelineCollectionReducer.pushFront(item, to: &items)
        case .remove(let index):
            RoomTimelineCollectionReducer.remove(at: index, from: &items)
        }
    }
}

private extension RoomTimelineItemViewState {
    static func fixture(index: Int) -> Self {
        .init(
            messageId: "fixture-\(index)",
            senderDisplayName: index.isMultiple(of: 2) ? "Ari" : "Sam",
            body: "Fixture message \(index)",
            sentAtLabel: "09:41",
            direction: index.isMultiple(of: 2) ? .incoming : .outgoing,
            deliveryState: index.isMultiple(of: 3) ? .read : .delivered
        )
    }
}
