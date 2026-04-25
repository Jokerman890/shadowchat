import ShadowDesignSystem
import SwiftUI

public struct ChatListView: View {
    private let state: ChatListState
    private let send: (ChatListEvent) -> Void

    public init(
        state: ChatListState,
        send: @escaping (ChatListEvent) -> Void
    ) {
        self.state = state
        self.send = send
    }

    public var body: some View {
        content
            .navigationTitle("Chats")
            .background(ShadowColors.background)
            .task {
                send(.appeared)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            ProgressView("Loading chats")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Loading chats")
        case let .loaded(items):
            List(items) { item in
                Button {
                    send(.roomSelected(roomId: item.roomId))
                } label: {
                    ChatListRow(item: item)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel(for: item))
            }
            .listStyle(.plain)
            .refreshable {
                send(.refreshRequested)
            }
        case .empty:
            ContentUnavailableView(
                "No chats yet",
                systemImage: "bubble.left.and.bubble.right",
                description: Text("New conversations will appear here.")
            )
            .accessibilityLabel("No chats yet")
        case .failed:
            ContentUnavailableView {
                Label("Chats unavailable", systemImage: "exclamationmark.triangle")
            } description: {
                Text("Try again when your connection is stable.")
            } actions: {
                Button("Retry") {
                    send(.retryRequested)
                }
            }
            .accessibilityLabel("Chats unavailable")
        }
    }

    private func accessibilityLabel(for item: ChatListItemViewState) -> String {
        var parts = [item.title]

        if item.unreadCount > 0 {
            parts.append("\(item.unreadCount) unread")
        }

        switch item.trustLevel {
        case .verified:
            parts.append("verified")
        case .standard:
            parts.append("standard trust")
        case .reduced:
            parts.append("reduced trust")
        }

        return parts.joined(separator: ", ")
    }
}

private struct ChatListRow: View {
    let item: ChatListItemViewState

    var body: some View {
        HStack(spacing: ShadowSpacing.md) {
            TrustIndicator(trustLevel: item.trustLevel)

            Text(item.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if item.unreadCount > 0 {
                Text("\(item.unreadCount)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .padding(.horizontal, ShadowSpacing.sm)
                    .padding(.vertical, ShadowSpacing.xs)
                    .background(Capsule().fill(ShadowColors.unreadBadge))
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, ShadowSpacing.sm)
        .contentShape(Rectangle())
    }
}

private struct TrustIndicator: View {
    let trustLevel: ChatListTrustLevel

    var body: some View {
        Image(systemName: symbolName)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(ShadowColors.trustColor(for: trustLevel.designTone))
            .frame(width: 24, height: 24)
            .accessibilityHidden(true)
    }

    private var symbolName: String {
        switch trustLevel {
        case .verified:
            return "checkmark.seal.fill"
        case .standard:
            return "circle"
        case .reduced:
            return "exclamationmark.triangle.fill"
        }
    }
}
