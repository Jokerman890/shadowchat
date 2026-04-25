#if DEBUG
import SwiftUI

#Preview("Loaded") {
    NavigationStack {
        ChatListView(
            state: .loaded(items: [
                ChatListItemViewState(
                    roomId: "verified-room",
                    title: "Security Review",
                    unreadCount: 2,
                    trustLevel: .verified
                ),
                ChatListItemViewState(
                    roomId: "standard-room",
                    title: "Weekend Plans",
                    unreadCount: 0,
                    trustLevel: .standard
                ),
                ChatListItemViewState(
                    roomId: "reduced-room",
                    title: "Bridge Room",
                    unreadCount: 12,
                    trustLevel: .reduced
                )
            ]),
            send: { _ in }
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        ChatListView(state: .empty, send: { _ in })
    }
    .environment(\.dynamicTypeSize, .accessibility2)
}

#Preview("Error") {
    NavigationStack {
        ChatListView(state: .failed, send: { _ in })
    }
    .preferredColorScheme(.dark)
}
#endif
