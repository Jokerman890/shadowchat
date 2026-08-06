import Foundation
import Observation

@MainActor
@Observable
public final class ShadowNotificationRouter {
    public static let shared = ShadowNotificationRouter()

    public private(set) var pendingRoomID: String?

    public init() {}

    public func route(toRoomID roomID: String) {
        let normalizedRoomID = roomID.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !normalizedRoomID.isEmpty else { return }
        pendingRoomID = normalizedRoomID
    }

    public func consumePendingRoomID() -> String? {
        defer { pendingRoomID = nil }
        return pendingRoomID
    }
}
