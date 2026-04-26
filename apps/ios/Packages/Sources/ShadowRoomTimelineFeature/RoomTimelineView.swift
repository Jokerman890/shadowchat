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
        ShadowLiquidBackground {
            VStack(spacing: ShadowSpacing.md) {
                header
                content
            }
            .padding(.horizontal, ShadowSpacing.lg)
            .padding(.top, ShadowSpacing.xl)
        }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                send(.appeared)
            }
    }

    private var header: some View {
        ShadowGlassPanel {
            HStack(spacing: ShadowSpacing.md) {
                Text("SC")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(shadowAccentGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: ShadowSpacing.xs) {
                    Text(title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(ShadowColors.deepText)
                        .lineLimit(1)
                    Text("Timeline shell")
                        .font(.subheadline)
                        .foregroundStyle(ShadowColors.softText)
                }

                Spacer()

                Image(systemName: "phone.fill")
                    .foregroundStyle(ShadowColors.unreadBadge)
                    .accessibilityLabel("Call")
                Image(systemName: "video.fill")
                    .foregroundStyle(ShadowColors.unreadBadge)
                    .accessibilityLabel("Video")
            }
            .padding(ShadowSpacing.md)
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
            Spacer()
            ShadowGlassPanel {
                ProgressView("Loading messages")
                    .padding(ShadowSpacing.xl)
                    .accessibilityLabel("Loading messages")
            }
            .frame(maxWidth: .infinity)
            Spacer()
        case let .loaded(_, items):
            VStack(spacing: ShadowSpacing.md) {
                ScrollView {
                    LazyVStack(spacing: ShadowSpacing.sm) {
                        Text("Today")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(ShadowColors.softText)
                            .padding(.horizontal, ShadowSpacing.md)
                            .padding(.vertical, ShadowSpacing.xs)
                            .background(.ultraThinMaterial, in: Capsule())

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

                TimelineComposer()
            }
        case .empty:
            Spacer()
            RoomTimelineGlassState(
                title: "No messages yet",
                symbolName: "bubble.left",
                description: "Messages in this room will appear here."
            )
            .accessibilityLabel("No messages yet")
            Spacer()
        case .failed:
            Spacer()
            ShadowGlassPanel {
                VStack(spacing: ShadowSpacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(ShadowColors.trustColor(for: .reduced))
                    Text("Messages unavailable")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(ShadowColors.deepText)
                    Text("Try again when your connection is stable.")
                        .font(.body)
                        .foregroundStyle(ShadowColors.softText)
                    Button("Retry") {
                        send(.retryRequested)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .multilineTextAlignment(.center)
                .padding(ShadowSpacing.xl)
            }
            .accessibilityLabel("Messages unavailable")
            Spacer()
        }
    }
}

private struct TimelineComposer: View {
    var body: some View {
        ShadowGlassPanel {
            HStack(spacing: ShadowSpacing.sm) {
                Text("Message shell")
                    .foregroundStyle(ShadowColors.softText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(ShadowColors.unreadBadge)
                    .accessibilityLabel("Send")
            }
            .padding(ShadowSpacing.md)
        }
        .padding(.horizontal, ShadowSpacing.lg)
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
        .padding(.vertical, ShadowSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ShadowRadii.bubble, style: .continuous)
                .fill(backgroundStyle)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ShadowRadii.bubble, style: .continuous)
                .stroke(.white.opacity(0.48), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 8)
        .frame(maxWidth: 320, alignment: item.direction == .outgoing ? .trailing : .leading)
    }

    private var backgroundStyle: Color {
        switch item.direction {
        case .incoming:
            return ShadowColors.incomingBubble
        case .outgoing:
            return ShadowColors.outgoingBubble
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

private struct RoomTimelineGlassState: View {
    let title: String
    let symbolName: String
    let description: String

    var body: some View {
        ShadowGlassPanel {
            VStack(spacing: ShadowSpacing.md) {
                Image(systemName: symbolName)
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(shadowAccentGradient)
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(ShadowColors.deepText)
                Text(description)
                    .font(.body)
                    .foregroundStyle(ShadowColors.softText)
            }
            .multilineTextAlignment(.center)
            .padding(ShadowSpacing.xl)
        }
        .frame(maxWidth: .infinity)
    }
}
