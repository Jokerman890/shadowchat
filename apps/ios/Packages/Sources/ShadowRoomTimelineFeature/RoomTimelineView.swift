import Foundation
import ShadowDesignSystem
import SwiftUI

public struct RoomTimelineView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let state: RoomTimelineState
    private let securityState: RoomTimelineSecurityState
    private let draft: String
    private let isSending: Bool
    private let sendErrorMessage: String?
    private let send: (RoomTimelineEvent) -> Void

    public init(
        state: RoomTimelineState,
        securityState: RoomTimelineSecurityState = .unknown,
        draft: String = "",
        isSending: Bool = false,
        sendErrorMessage: String? = nil,
        send: @escaping (RoomTimelineEvent) -> Void
    ) {
        self.state = state
        self.securityState = securityState
        self.draft = draft
        self.isSending = isSending
        self.sendErrorMessage = sendErrorMessage
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if supportsComposer {
                composerSurface
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
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
                    Label(securityLabel, systemImage: securitySymbol)
                        .font(.subheadline)
                        .foregroundStyle(securityColor)
                }

                Spacer()

                Image(systemName: securityBadgeSymbol)
                    .foregroundStyle(securityColor)
                    .accessibilityLabel(securityLabel)
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

    private var securityLabel: String {
        switch securityState {
        case .encrypted:
            return "Ende-zu-Ende verschlüsselt"
        case .unencrypted:
            return "Nicht Ende-zu-Ende verschlüsselt"
        case .unknown:
            return "Verschlüsselungsstatus unbekannt"
        }
    }

    private var securitySymbol: String {
        switch securityState {
        case .encrypted:
            return "lock.fill"
        case .unencrypted:
            return "lock.open.fill"
        case .unknown:
            return "questionmark.circle"
        }
    }

    private var securityBadgeSymbol: String {
        switch securityState {
        case .encrypted:
            return "lock.shield.fill"
        case .unencrypted:
            return "exclamationmark.shield.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }

    private var securityColor: Color {
        switch securityState {
        case .encrypted:
            return ShadowColors.whatsAppGreen
        case .unencrypted:
            return .orange
        case .unknown:
            return ShadowColors.softText
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
                            .transition(.opacity.combined(with: .scale(scale: 0.985)))
                    }
                }
                .padding(.horizontal, ShadowSpacing.lg)
                .padding(.vertical, ShadowSpacing.md)
                .animation(
                    ShadowMotion.stateTransition(reduceMotion: reduceMotion),
                    value: items.map(\.messageId)
                )
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable {
                send(.refreshRequested)
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

    private var supportsComposer: Bool {
        switch state {
        case .loaded, .empty:
            return true
        case .loading, .failed:
            return false
        }
    }

    private var composerSurface: some View {
        VStack(spacing: ShadowSpacing.xs) {
            if let sendErrorMessage {
                Label(sendErrorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, ShadowSpacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            TimelineComposer(
                draft: draft,
                isSending: isSending,
                draftChanged: { send(.draftChanged($0)) },
                sendRequested: { send(.sendRequested) }
            )
        }
        .padding(.vertical, ShadowSpacing.sm)
        .background(.ultraThinMaterial)
    }
}

private struct TimelineComposer: View {
    let draft: String
    let isSending: Bool
    let draftChanged: (String) -> Void
    let sendRequested: () -> Void

    var body: some View {
        ShadowGlassPanel {
            HStack(spacing: ShadowSpacing.sm) {
                TextField(
                    "Nachricht",
                    text: Binding(
                        get: { draft },
                        set: { updatedDraft in
                            draftChanged(updatedDraft)
                        }
                    ),
                    axis: .vertical
                )
                .lineLimit(1...5)
                .submitLabel(.send)
                .onSubmit(sendRequested)
                Button(action: sendRequested) {
                    if isSending {
                        ProgressView()
                            .tint(.black)
                            .frame(width: 42, height: 42)
                            .background(shadowAccentGradient, in: Circle())
                    } else {
                        ComposerIcon(systemName: "paperplane.fill", label: "Send", emphasized: true)
                    }
                }
                .buttonStyle(.plain)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            }
            .padding(.horizontal, ShadowSpacing.md)
            .padding(.vertical, ShadowSpacing.sm)
        }
        .padding(.horizontal, ShadowSpacing.lg)
    }
}

private struct ComposerIcon: View {
    let systemName: String
    let label: String
    var emphasized: Bool = false

    var body: some View {
        Image(systemName: systemName)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(emphasized ? .white : ShadowColors.unreadBadge)
            .frame(width: 42, height: 42)
            .background(emphasized ? AnyShapeStyle(shadowAccentGradient) : AnyShapeStyle(.ultraThinMaterial), in: Circle())
            .overlay(Circle().stroke(.white.opacity(emphasized ? 0.0 : 0.55), lineWidth: 0.8))
            .accessibilityLabel(label)
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
