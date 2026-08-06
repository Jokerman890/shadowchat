import XCTest
@testable import ShadowRoomTimelineFeature

final class RoomTimelineCollectionReducerTests: XCTestCase {
    func testProjectionPreservesOrderAndDropsNilResults() {
        let result = RoomTimelineProjection.map([1, 2, 3, 4]) { value in
            value.isMultiple(of: 2) ? "item-\(value)" : nil
        }

        XCTAssertEqual(result, ["item-2", "item-4"])
    }

    func testProjectionMapsPresentationFieldsAndSendState() {
        let input = RoomTimelineProjectionInput(
            identifier: TestIdentifier(value: "event-1"),
            senderDisplayName: "Ari",
            body: "Hello",
            timestampMilliseconds: 1_784_800_000_000,
            direction: .outgoing,
            sendState: .sendingFailed
        )

        let result = RoomTimelineProjection.makeItem(input)

        XCTAssertEqual(result.messageId, "event-1")
        XCTAssertEqual(result.senderDisplayName, "Ari")
        XCTAssertEqual(result.body, "Hello")
        XCTAssertFalse(result.sentAtLabel.isEmpty)
        XCTAssertEqual(result.direction, .outgoing)
        XCTAssertEqual(result.deliveryState, .failed)
    }

    func testProjectionMapsAllSendStates() {
        let cases: [
            (RoomTimelineProjectionSendState, RoomTimelineDeliveryState)
        ] = [
            (.notSentYet, .sending),
            (.sendingFailed, .failed),
            (.sent, .sent),
            (.remote, .delivered)
        ]

        for (sendState, expectedDeliveryState) in cases {
            let input = RoomTimelineProjectionInput(
                identifier: TestIdentifier(value: "event"),
                senderDisplayName: nil,
                body: "Message",
                timestampMilliseconds: 1_784_800_000_000,
                direction: .incoming,
                sendState: sendState
            )

            XCTAssertEqual(
                RoomTimelineProjection.makeItem(input).deliveryState,
                expectedDeliveryState
            )
        }
    }

    func testReducerAppliesAllSupportedMutations() {
        var items = [1, 2, 3]

        RoomTimelineCollectionReducer.append([4, 5], to: &items)
        RoomTimelineCollectionReducer.insert(0, at: -1, in: &items)
        RoomTimelineCollectionReducer.set(30, at: 3, in: &items)
        RoomTimelineCollectionReducer.remove(at: 1, from: &items)
        RoomTimelineCollectionReducer.pushFront(-1, to: &items)
        RoomTimelineCollectionReducer.pushBack(6, to: &items)
        RoomTimelineCollectionReducer.popFront(&items)
        RoomTimelineCollectionReducer.popBack(&items)
        RoomTimelineCollectionReducer.truncate(&items, to: 4)

        XCTAssertEqual(items, [0, 2, 30, 4])

        RoomTimelineCollectionReducer.reset([7, 8], in: &items)
        XCTAssertEqual(items, [7, 8])

        RoomTimelineCollectionReducer.clear(&items)
        XCTAssertTrue(items.isEmpty)
    }

    func testReducerIgnoresInvalidSetAndRemoveIndices() {
        var items = [1, 2, 3]

        RoomTimelineCollectionReducer.set(4, at: 4, in: &items)
        RoomTimelineCollectionReducer.remove(at: -1, from: &items)

        XCTAssertEqual(items, [1, 2, 3])
    }
}

private struct TestIdentifier: CustomStringConvertible {
    let value: String

    var description: String {
        value
    }
}
