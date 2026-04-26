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
        ShadowLiquidBackground {
            VStack(alignment: .leading, spacing: ShadowSpacing.md) {
                header
                content
            }
            .padding(.horizontal, ShadowSpacing.lg)
            .padding(.top, ShadowSpacing.xl)
        }
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                send(.appeared)
            }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: ShadowSpacing.md) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: ShadowSpacing.xs) {
                    Text("Chats")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(ShadowColors.deepText)

                    Text("Private rooms, soft signals, clear trust.")
                        .font(.subheadline)
                        .foregroundStyle(ShadowColors.softText)
                }

                Spacer()

                Image(systemName: "plus")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(shadowAccentGradient, in: Circle())
                    .accessibilityLabel("New chat")
            }

            HStack(spacing: ShadowSpacing.sm) {
                filterChip("All")
                filterChip("Unread")
                filterChip("Groups")
                filterChip("Favorites")
            }

            Text("Search conversations")
                .font(.subheadline)
                .foregroundStyle(ShadowColors.softText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, ShadowSpacing.lg)
                .padding(.vertical, ShadowSpacing.md)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.62), lineWidth: 0.8))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
    }

    private func filterChip(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(ShadowColors.deepText)
            .padding(.horizontal, ShadowSpacing.md)
            .padding(.vertical, ShadowSpacing.sm)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.55), lineWidth: 0.8))
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            Spacer()
            ShadowGlassPanel {
                ProgressView("Loading chats")
                    .padding(ShadowSpacing.xl)
                    .accessibilityLabel("Loading chats")
            }
            .frame(maxWidth: .infinity)
            Spacer()
        case let .loaded(items):
            ScrollView {
                LazyVStack(spacing: ShadowSpacing.md) {
                    ForEach(items) { item in
                        Button {
                            send(.roomSelected(roomId: item.roomId))
                        } label: {
                            ChatListRow(item: item)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(accessibilityLabel(for: item))
                    }
                }
                .padding(.vertical, ShadowSpacing.xs)
            }
            .refreshable {
                send(.refreshRequested)
            }
        case .empty:
            Spacer()
            EmptyGlassState(
                title: "No chats yet",
                symbolName: "bubble.left.and.bubble.right",
                description: "New conversations will appear here."
            )
            .accessibilityLabel("No chats yet")
            Spacer()
        case .failed:
            Spacer()
            ShadowGlassPanel {
                VStack(spacing: ShadowSpacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(ShadowColors.trustColor(for: .reduced))
                    Text("Chats unavailable")
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
            .accessibilityLabel("Chats unavailable")
            Spacer()
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
        ShadowGlassPanel(radius: ShadowRadii.card) {
            HStack(spacing: ShadowSpacing.md) {
                AvatarBadge(title: item.title)

                VStack(alignment: .leading, spacing: ShadowSpacing.xs) {
                    HStack(spacing: ShadowSpacing.sm) {
                        Text(item.title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(ShadowColors.deepText)
                            .lineLimit(1)

                        TrustIndicator(trustLevel: item.trustLevel)
                    }

                    Text(item.previewText.isEmpty ? previewLine : item.previewText)
                        .font(.subheadline)
                        .foregroundStyle(ShadowColors.softText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !item.sentAtLabel.isEmpty {
                    Text(item.sentAtLabel)
                        .font(.caption2)
                        .foregroundStyle(ShadowColors.softText)
                }

                if item.unreadCount > 0 {
                    Text("\(item.unreadCount)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .padding(.horizontal, ShadowSpacing.sm)
                        .padding(.vertical, ShadowSpacing.xs)
                        .background(shadowAccentGradient, in: Capsule())
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, ShadowSpacing.md)
            .padding(.vertical, ShadowSpacing.md)
        }
        .contentShape(RoundedRectangle(cornerRadius: ShadowRadii.card, style: .continuous))
    }

    private var previewLine: String {
        switch item.trustLevel {
        case .verified:
            return "Verified secure conversation"
        case .standard:
            return "Standard private conversation"
        case .reduced:
            return "Reduced trust context"
        }
    }
}

private struct AvatarBadge: View {
    let title: String

    var body: some View {
        Text(String(title.first ?? " ").uppercased())
            .font(.title3.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 54, height: 54)
            .background(shadowAccentGradient, in: Circle())
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

private struct EmptyGlassState: View {
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
