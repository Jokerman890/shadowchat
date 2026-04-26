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
                    router?.openRoom(roomId)
                }
            )
        )
    }

    public var body: some View {
        ShadowLiquidBackground {
            TabView(selection: $router.selectedTab) {
                NavigationStack(path: $router.chatPath) {
                    ChatListRoute(viewModel: chatListViewModel)
                        .navigationDestination(for: String.self) { roomId in
                            RoomTimelineRoute(
                                viewModel: RoomTimelineViewModel(
                                    roomId: roomId,
                                    repository: DemoRoomTimelineRepository()
                                )
                            )
                        }
                }
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(ShadowShellTab.chats)

                CallsShellView()
                    .tabItem {
                        Label("Calls", systemImage: "phone.fill")
                    }
                    .tag(ShadowShellTab.calls)

                UpdatesShellView()
                    .tabItem {
                        Label("Updates", systemImage: "sparkles")
                    }
                    .tag(ShadowShellTab.updates)

                ProfileShellView()
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle.fill")
                    }
                    .tag(ShadowShellTab.profile)

                SettingsShellView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(ShadowShellTab.settings)
            }
            .tint(ShadowColors.unreadBadge)
            .onChange(of: router.selectedTab) { _, tab in
                if tab != .chats {
                    router.closeRoom()
                }
            }
        }
    }
}

private enum ShadowShellTab: Hashable {
    case chats
    case calls
    case updates
    case profile
    case settings
}

@MainActor
private final class ShadowChatRouter: ObservableObject {
    @Published var selectedTab: ShadowShellTab = .chats
    @Published var chatPath = NavigationPath()

    func openRoom(_ roomId: String) {
        selectedTab = .chats
        chatPath = NavigationPath()
        chatPath.append(roomId)
    }

    func closeRoom() {
        chatPath = NavigationPath()
    }
}

private struct CallsShellView: View {
    var body: some View {
        ShellScreen(title: "Calls", symbolName: "phone.fill") {
            PillRow(labels: ShadowDemoData.callFilters)
            ForEach(ShadowDemoData.callRows) { row in
                ShellRow(title: row.title, subtitle: row.subtitle, trailing: row.trailing)
            }
        }
    }
}

private struct UpdatesShellView: View {
    var body: some View {
        ShellScreen(title: "Updates", symbolName: "sparkles") {
            ForEach(ShadowDemoData.updateRows) { row in
                ShellRow(title: row.title, subtitle: row.subtitle, trailing: row.trailing)
            }
        }
    }
}

private struct ProfileShellView: View {
    var body: some View {
        ShellScreen(title: "Profile", symbolName: "person.crop.circle.fill") {
            AvatarHero(name: ShadowDemoData.profileHero.name, subtitle: ShadowDemoData.profileHero.subtitle)
            PillRow(labels: ShadowDemoData.profileActions)
            ForEach(ShadowDemoData.profileRows) { row in
                ShellRow(title: row.title, subtitle: row.subtitle, trailing: row.trailing)
            }
        }
    }
}

private struct SettingsShellView: View {
    var body: some View {
        ShellScreen(title: "Settings", symbolName: "gearshape.fill") {
            AvatarHero(name: ShadowDemoData.settingsHero.name, subtitle: ShadowDemoData.settingsHero.subtitle)
            ForEach(ShadowDemoData.settingsRows) { row in
                ShellRow(title: row.title, subtitle: row.subtitle, trailing: row.trailing)
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

#if DEBUG
#Preview {
    ShadowChatRootView()
}
#endif
