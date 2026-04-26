import ShadowChatListFeature
import ShadowDesignSystem
import ShadowRoomTimelineFeature
import SwiftUI

public struct ShadowChatRootView: View {
    @StateObject private var router: ShadowChatRouter
    @StateObject private var chatListViewModel: ChatListViewModel

    public init() {
        let router = ShadowChatRouter()
        _router = StateObject(wrappedValue: router)
        _chatListViewModel = StateObject(
            wrappedValue: ChatListViewModel(
                repository: DemoChatListRepository(),
                onRoomSelected: { [weak router] roomId in
                    router?.selectedRoomId = roomId
                }
            )
        )
    }

    public var body: some View {
        ShadowLiquidBackground {
            TabView {
                NavigationStack {
                    if let roomId = router.selectedRoomId {
                        VStack(spacing: ShadowSpacing.sm) {
                            Button {
                                router.selectedRoomId = nil
                            } label: {
                                Label("Chats", systemImage: "chevron.left")
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, ShadowSpacing.lg)

                            RoomTimelineRoute(
                                viewModel: RoomTimelineViewModel(
                                    roomId: roomId,
                                    repository: DemoRoomTimelineRepository()
                                )
                            )
                        }
                    } else {
                        ChatListRoute(viewModel: chatListViewModel)
                    }
                }
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right.fill")
                }

                CallsShellView()
                    .tabItem {
                        Label("Calls", systemImage: "phone.fill")
                    }

                UpdatesShellView()
                    .tabItem {
                        Label("Updates", systemImage: "sparkles")
                    }

                ProfileShellView()
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle.fill")
                    }

                SettingsShellView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            .tint(ShadowColors.unreadBadge)
        }
    }
}

@MainActor
private final class ShadowChatRouter: ObservableObject {
    @Published var selectedRoomId: String?
}

private struct CallsShellView: View {
    var body: some View {
        ShellScreen(title: "Calls", symbolName: "phone.fill") {
            PillRow(labels: ["All", "Missed", "Voicemail"])
            ShellRow(title: "Sofia Martin", subtitle: "Outgoing call, today", trailing: "Call")
            ShellRow(title: "Daniel Carter", subtitle: "Missed call, yesterday", trailing: "Call")
            ShellRow(title: "Adventure Club", subtitle: "Group call preview", trailing: "Call")
        }
    }
}

private struct UpdatesShellView: View {
    var body: some View {
        ShellScreen(title: "Updates", symbolName: "sparkles") {
            ShellRow(title: "My Status", subtitle: "Add a soft glass status update", trailing: "New")
            ShellRow(title: "Emma Wilson", subtitle: "Recent update", trailing: "View")
            ShellRow(title: "Family", subtitle: "Viewed update", trailing: "View")
        }
    }
}

private struct ProfileShellView: View {
    var body: some View {
        ShellScreen(title: "Profile", symbolName: "person.crop.circle.fill") {
            AvatarHero(name: "Sofia Martin", subtitle: "Online now")
            PillRow(labels: ["Message", "Call", "Video", "Pay"])
            ShellRow(title: "About", subtitle: "Building calm, secure conversations.", trailing: "Edit")
            ShellRow(title: "Media, Links, Docs", subtitle: "24 shared items", trailing: "Open")
            ShellRow(title: "Starred Messages", subtitle: "Quick access shell", trailing: "Open")
        }
    }
}

private struct SettingsShellView: View {
    var body: some View {
        ShellScreen(title: "Settings", symbolName: "gearshape.fill") {
            AvatarHero(name: "ShadowChat", subtitle: "Premium messenger shell")
            ForEach([
                "Account",
                "Privacy",
                "Notifications",
                "Appearance",
                "Chats",
                "Storage and Data",
                "Help Center",
                "Invite Friends"
            ], id: \.self) { title in
                ShellRow(title: title, subtitle: "Settings group shell", trailing: "Open")
            }
        }
    }
}

private struct ShellScreen<Content: View>: View {
    let title: String
    let symbolName: String
    private let content: Content

    init(
        title: String,
        symbolName: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.symbolName = symbolName
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            ShadowLiquidBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: ShadowSpacing.md) {
                        HStack(spacing: ShadowSpacing.md) {
                            Image(systemName: symbolName)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 54, height: 54)
                                .background(shadowAccentGradient, in: Circle())

                            Text(title)
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(ShadowColors.deepText)
                        }

                        content
                    }
                    .padding(ShadowSpacing.lg)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct PillRow: View {
    let labels: [String]

    var body: some View {
        HStack(spacing: ShadowSpacing.sm) {
            ForEach(labels, id: \.self) { label in
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, ShadowSpacing.md)
                    .padding(.vertical, ShadowSpacing.sm)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.55), lineWidth: 1))
            }
        }
    }
}

private struct AvatarHero: View {
    let name: String
    let subtitle: String

    var body: some View {
        ShadowGlassPanel {
            HStack(spacing: ShadowSpacing.md) {
                DemoAvatar(initial: String(name.first ?? "S"))
                VStack(alignment: .leading) {
                    Text(name)
                        .font(.title2.weight(.bold))
                    Text(subtitle)
                        .foregroundStyle(ShadowColors.softText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(ShadowSpacing.lg)
        }
    }
}

private struct ShellRow: View {
    let title: String
    let subtitle: String
    let trailing: String

    var body: some View {
        ShadowGlassPanel(radius: ShadowRadii.card) {
            HStack(spacing: ShadowSpacing.md) {
                DemoAvatar(initial: String(title.first ?? "S"))
                VStack(alignment: .leading, spacing: ShadowSpacing.xs) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(ShadowColors.softText)
                }
                Spacer()
                Text(trailing)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ShadowColors.unreadBadge)
            }
            .padding(ShadowSpacing.md)
        }
    }
}

private struct DemoAvatar: View {
    let initial: String

    var body: some View {
        Text(initial.uppercased())
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 52, height: 52)
            .background(shadowAccentGradient, in: Circle())
    }
}

private struct DemoChatListRepository: ChatListRepository {
    func loadChatList() async throws -> [ChatListItemViewState] {
        [
            ChatListItemViewState(roomId: "sofia", title: "Sofia Martin", previewText: "Hey! Are we still on for dinner tonight?", sentAtLabel: "09:41", unreadCount: 2, trustLevel: .verified, isFavorite: true),
            ChatListItemViewState(roomId: "design-squad", title: "Design Squad", previewText: "Liam: I'll share the assets here.", sentAtLabel: "09:12", unreadCount: 8, trustLevel: .standard, isFavorite: true),
            ChatListItemViewState(roomId: "jason", title: "Jason Lee", previewText: "Sounds good, talk soon!", sentAtLabel: "Yesterday", unreadCount: 0, trustLevel: .verified),
            ChatListItemViewState(roomId: "family", title: "Family", previewText: "Mom: Don't forget Sunday lunch at grandma's!", sentAtLabel: "Sun", unreadCount: 4, trustLevel: .standard),
            ChatListItemViewState(roomId: "emma", title: "Emma Wilson", previewText: "Looks amazing!", sentAtLabel: "Sat", unreadCount: 1, trustLevel: .verified),
            ChatListItemViewState(roomId: "adventure", title: "Adventure Club", previewText: "Trail photos are ready.", sentAtLabel: "Fri", unreadCount: 0, trustLevel: .reduced),
            ChatListItemViewState(roomId: "noah", title: "Noah Johnson", previewText: "Can you review this later?", sentAtLabel: "Thu", unreadCount: 0, trustLevel: .standard),
            ChatListItemViewState(roomId: "daniel", title: "Daniel Carter", previewText: "Call me when you are free.", sentAtLabel: "Wed", unreadCount: 3, trustLevel: .reduced)
        ]
    }
}

private struct DemoRoomTimelineRepository: RoomTimelineRepository {
    func loadTimeline(roomId: String) async throws -> RoomTimelineSnapshotViewState {
        let rooms = try await DemoChatListRepository().loadChatList()
        let title = rooms.first { $0.roomId == roomId }?.title ?? "Conversation"

        return RoomTimelineSnapshotViewState(
            roomId: roomId,
            roomTitle: title,
            items: [
                RoomTimelineItemViewState(messageId: "m1", senderDisplayName: title, body: "Hey! Are we still on for dinner tonight?", sentAtLabel: "09:41", direction: .incoming, deliveryState: .read),
                RoomTimelineItemViewState(messageId: "m2", senderDisplayName: nil, body: "Yes. I will be there at 8.", sentAtLabel: "09:43", direction: .outgoing, deliveryState: .delivered),
                RoomTimelineItemViewState(messageId: "m3", senderDisplayName: title, body: "Perfect. I saved us a table near the window.", sentAtLabel: "09:44", direction: .incoming, deliveryState: .read),
                RoomTimelineItemViewState(messageId: "m4", senderDisplayName: nil, body: "Voice preview and media cards will land in the send pipeline slice.", sentAtLabel: "09:45", direction: .outgoing, deliveryState: .sent)
            ]
        )
    }
}

#if DEBUG
#Preview {
    ShadowChatRootView()
}
#endif
