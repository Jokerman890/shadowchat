import ShadowChatListFeature
import ShadowCoreContracts
import ShadowDesignSystem
import ShadowRoomTimelineFeature
import SwiftUI

public struct ShadowChatRootView: View {
    @State private var appState: ShadowAppState

    private let repositoryProvider: any ShadowRepositoryProvider
    private let notificationRouter: ShadowNotificationRouter

    public init() {
        self.init(
            appState: ShadowAppState(),
            repositoryProvider: DemoShadowRepositoryProvider(),
            notificationRouter: .shared
        )
    }

    public init(appState: ShadowAppState) {
        self.init(
            appState: appState,
            repositoryProvider: DemoShadowRepositoryProvider(),
            notificationRouter: .shared
        )
    }

    public init(
        appState: ShadowAppState,
        repositoryProvider: any ShadowRepositoryProvider,
        notificationRouter: ShadowNotificationRouter = .shared
    ) {
        _appState = State(initialValue: appState)
        self.repositoryProvider = repositoryProvider
        self.notificationRouter = notificationRouter
    }

    public var body: some View {
        Group {
            switch appState.session.state {
            case .launching, .restoring:
                ShadowLaunchView()
            case .signedOut, .failed, .expired:
                ShadowOnboardingView(appState: appState)
            case .discovering, .authenticating:
                ShadowLaunchView(message: "Sichere Anmeldung wird vorbereitet")
            case .active, .syncing, .offline, .locked:
                ShadowAuthenticatedShell(
                    appState: appState,
                    repositoryProvider: repositoryProvider,
                    notificationRouter: notificationRouter
                )
            }
        }
        .task {
            await appState.launch()
        }
        .alert(
            "ShadowChat",
            isPresented: Binding(
                get: { appState.errorMessage != nil },
                set: { if !$0 { appState.clearError() } }
            )
        ) {
            Button("OK") {
                appState.clearError()
            }
        } message: {
            Text(appState.errorMessage ?? "")
        }
        .preferredColorScheme(.dark)
    }
}

private struct ShadowAuthenticatedShell: View {
    @Bindable var appState: ShadowAppState

    private let repositoryProvider: any ShadowRepositoryProvider
    @Bindable private var notificationRouter: ShadowNotificationRouter

    @State private var selectedTab: ShadowShellTab = .chats
    @State private var chatPath = NavigationPath()

    init(
        appState: ShadowAppState,
        repositoryProvider: any ShadowRepositoryProvider,
        notificationRouter: ShadowNotificationRouter
    ) {
        self.appState = appState
        self.repositoryProvider = repositoryProvider
        self.notificationRouter = notificationRouter
    }

    var body: some View {
        ShadowLiquidBackground {
            TabView(selection: $selectedTab) {
                NavigationStack(path: $chatPath) {
                    ChatListRoute(
                        viewModel: ChatListViewModel(
                            repository: repositoryProvider.makeChatListRepository(),
                            onRoomSelected: openRoom
                        )
                    )
                    .navigationDestination(for: String.self) { roomID in
                        RoomTimelineRoute(
                            viewModel: RoomTimelineViewModel(
                                roomId: roomID,
                                repository: repositoryProvider.makeRoomTimelineRepository(roomId: roomID)
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
                        Label("Anrufe", systemImage: "phone.fill")
                    }
                    .tag(ShadowShellTab.calls)

                ShadowBridgeHubView(appState: appState)
                    .tabItem {
                        Label("Bridges", systemImage: "point.3.connected.trianglepath.dotted")
                    }
                    .tag(ShadowShellTab.bridges)

                ShadowSettingsView(appState: appState)
                    .tabItem {
                        Label("Einstellungen", systemImage: "gearshape.fill")
                    }
                    .tag(ShadowShellTab.settings)
            }
            .tint(ShadowColors.whatsAppGreen)
            .onChange(of: selectedTab) { _, tab in
                if tab != .chats {
                    chatPath = NavigationPath()
                }
            }
            .task {
                openPendingNotificationRoom()
            }
            .onChange(of: notificationRouter.pendingRoomID) { _, _ in
                openPendingNotificationRoom()
            }
        }
        .sheet(
            isPresented: Binding(
                get: { appState.activePairingSession != nil },
                set: { isPresented in
                    if !isPresented {
                        Task { await appState.cancelPairing() }
                    }
                }
            )
        ) {
            if let pairing = appState.activePairingSession {
                ShadowPairingView(
                    pairing: pairing,
                    confirm: {
                        Task { await appState.confirmPairing() }
                    },
                    cancel: {
                        Task { await appState.cancelPairing() }
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private func openRoom(_ roomID: String) {
        selectedTab = .chats
        chatPath = NavigationPath()
        chatPath.append(roomID)
    }

    private func openPendingNotificationRoom() {
        guard let roomID = notificationRouter.consumePendingRoomID() else {
            return
        }
        openRoom(roomID)
    }
}

private enum ShadowShellTab: Hashable {
    case chats
    case calls
    case bridges
    case settings
}

private struct ShadowLaunchView: View {
    var message = "ShadowChat wird gestartet"

    var body: some View {
        ShadowLiquidBackground {
            VStack(spacing: ShadowSpacing.xl) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 92, height: 92)
                    .background(shadowAccentGradient, in: Circle())

                Text("ShadowChat")
                    .font(.largeTitle.weight(.bold))

                ProgressView(message)
                    .tint(ShadowColors.whatsAppGreen)
                    .foregroundStyle(ShadowColors.softText)
            }
            .padding(ShadowSpacing.xl)
        }
    }
}

private struct CallsShellView: View {
    var body: some View {
        NavigationStack {
            ShadowLiquidBackground {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ShadowSpacing.md) {
                        Text("Anrufe")
                            .font(.largeTitle.weight(.bold))

                        Text("Matrix-Calls bleiben getrennt von externen Bridge-Anrufen.")
                            .foregroundStyle(ShadowColors.softText)

                        ForEach(ShadowDemoData.callRows) { row in
                            ShadowGlassPanel(radius: ShadowRadii.card) {
                                HStack(spacing: ShadowSpacing.md) {
                                    AvatarBadge(title: row.title)
                                    VStack(alignment: .leading, spacing: ShadowSpacing.xs) {
                                        Text(row.title)
                                            .font(.headline)
                                        Text(row.subtitle)
                                            .font(.subheadline)
                                            .foregroundStyle(ShadowColors.softText)
                                    }
                                    Spacer()
                                    Image(systemName: "phone.fill")
                                        .foregroundStyle(ShadowColors.whatsAppGreen)
                                        .accessibilityLabel("Anrufen")
                                }
                                .padding(ShadowSpacing.md)
                            }
                        }
                    }
                    .padding(ShadowSpacing.lg)
                }
            }
            .navigationTitle("Anrufe")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct AvatarBadge: View {
    let title: String

    var body: some View {
        Text(String(title.first ?? "S").uppercased())
            .font(.headline.weight(.bold))
            .foregroundStyle(.black)
            .frame(width: 50, height: 50)
            .background(shadowAccentGradient, in: Circle())
    }
}

#if DEBUG
#Preview {
    ShadowChatRootView()
}
#endif
