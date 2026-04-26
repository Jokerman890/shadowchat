import ShadowDesignSystem
import SwiftUI

public struct RoomTimelineView: View {
    private let state: RoomTimelineState
    private let send: (RoomTimelineEvent) -> Void

    public init(
        state: RoomTimelineState,
        send: @escaping (RoomTimelineEvent) -> Void
    ) {
        self.state = state
        self.send = send
    }

    public var body: some View {
        content
            .navigationTitle(title)
            .background(ShadowColors.background)
            .task {
                send(.appeared)
            }
    }

    private var title: String {
        switch state {
        case .loaded(let roomTitle, _), .empty(let roomTitle):
            return roomTitle ?? "Room"
        case .failed, .loading:
            return "Room"
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            ProgressView("Loading messages")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Loading messages")
        case let .loaded(_, items):
            ScrollView {
                LazyVStack(spacing: ShadowSpacing.sm) {
                    ForEach(items) { item in
                        RoomTimelineMessageRow(item: item)
                    }
                }
                .padding(.horizontal, ShadowSpacing.lg)
                .padding(.vertical, ShadowSpacing.md)
            }
            .refreshable {
                send(.refreshRequested)
            }
        case .empty:
            ContentUnavailableView(
                "No messages yet",
                systemImage: "bubble.left",
                description: Text("Messages in this room will appear here.")
            )
            .accessibilityLabel("No messages yet")
        case .failed:
            ContentUnavailableView {
                Label("Messages unavailable", systemImage: "exclamationmark.triangle")
            } description: {
                Text("Try again when your connection is stable.")
            } actions: {
                Button("Retry") {
                    send(.retryRequested)
                }
            }
            .accessibilityLabel("Messages unavailable")
        }
    }
}

private struct RoomTimelineMessageRow: View {
    let item: RoomTimelineItemViewState

    var body: some View {
        HStack {
            if item.direction == .outgoing {
                Spacer(minLength: ShadowSpacing.xl)
            }

            MessageBubble(item: item)

            if item.direction == .incoming {
                Spacer(minLength: ShadowSpacing.xl)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let sender = item.senderDisplayName ?? "You"
        return "\(sender): \(item.body), \(item.sentAtLabel), \(deliveryStateLabel)"
    }

    private var deliveryStateLabel: String {
        switch item.deliveryState {
        case .sending:
            return "sending"
        case .sent:
            return "sent"
        case .delivered:
            return "delivered"
        case .read:
            return "read"
        case .failed:
            return "failed"
        }
    }
}

private struct MessageBubble: View {
    let item: RoomTimelineItemViewState

    var body: some View {
        VStack(alignment: .leading, spacing: ShadowSpacing.xs) {
            if item.direction == .incoming, let sender = item.senderDisplayName {
                Text(sender)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(item.body)
                .font(.body)
                .foregroundStyle(.primary)

            HStack(spacing: ShadowSpacing.xs) {
                Text(item.sentAtLabel)
                Text(deliveryStateLabel)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, ShadowSpacing.md)
        .padding(.vertical, ShadowSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(backgroundStyle)
        )
        .frame(maxWidth: 320, alignment: item.direction == .outgoing ? .trailing : .leading)
    }

    private var backgroundStyle: Color {
        switch item.direction {
        case .incoming:
            return ShadowColors.secondaryBackground
        case .outgoing:
            return Color.accentColor.opacity(0.18)
        }
    }

    private var deliveryStateLabel: String {
        switch item.deliveryState {
        case .sending:
            return "sending"
        case .sent:
            return "sent"
        case .delivered:
            return "delivered"
        case .read:
            return "read"
        case .failed:
            return "failed"
        }
    }
}
