import XCTest
@testable import ShadowRoomTimelineFeature

final class RoomTimelineCollectionReducerTests: XCTestCase {
    func testProjectionPreservesOrderAndDropsNilResults() {
        let result = RoomTimelineProjection.map([1, 2, 3, 4]) { value in
            value.isMultiple(of: 2) ? "item-\(value)" : nil
        }

        XCTAssertEqual(result, ["item-2", "item-4"])
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
