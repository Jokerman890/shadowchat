#if DEBUG
import SwiftUI

#Preview("Loaded") {
    NavigationStack {
        RoomTimelineView(
            state: .loaded(
                roomTitle: "Security Review",
                items: previewTimelineItems
            ),
            send: { _ in }
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        RoomTimelineView(
            state: .empty(roomTitle: "Weekend Plans"),
            send: { _ in }
        )
    }
    .environment(\.dynamicTypeSize, .accessibility2)
}

#Preview("Error") {
    NavigationStack {
        RoomTimelineView(state: .failed, send: { _ in })
    }
    .preferredColorScheme(.dark)
}

private let previewTimelineItems = [
    RoomTimelineItemViewState(
        messageId: "message-1",
        senderDisplayName: "Ari",
        body: "Can you review the key backup flow today?",
        sentAtLabel: "09:41",
        direction: .incoming,
        deliveryState: .read
    ),
    RoomTimelineItemViewState(
        messageId: "message-2",
        senderDisplayName: nil,
        body: "Yes. I will check the recovery wording before lunch.",
        sentAtLabel: "09:43",
        direction: .outgoing,
        deliveryState: .delivered
    )
]
#endif
