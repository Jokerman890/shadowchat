import ShadowChatAppShell
import SwiftUI
import UIKit
import UserNotifications

final class ShadowChatAppDelegate:
    NSObject,
    UIApplicationDelegate,
    UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            ShadowPushTokenBroker.shared.didRegister(deviceToken: deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: any Error
    ) {
        Task { @MainActor in
            ShadowPushTokenBroker.shared.didFailToRegister(error: error)
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let roomID = userInfo["shadowchat_room_id"] as? String
            ?? userInfo["room_id"] as? String
        guard let roomID else { return }
        await ShadowNotificationRouter.shared.route(toRoomID: roomID)
    }
}

@main
@MainActor
struct ShadowChatApp: App {
    @UIApplicationDelegateAdaptor(ShadowChatAppDelegate.self)
    private var appDelegate

    private let repositoryProvider: any ShadowRepositoryProvider
    private let notificationRouter: ShadowNotificationRouter
    @State private var appState: ShadowAppState

    init() {
        let composition = ShadowAppComposition.live()
        repositoryProvider = composition.repositoryProvider
        notificationRouter = composition.notificationRouter
        _appState = State(
            initialValue: composition.appState
        )
    }

    var body: some Scene {
        WindowGroup {
            ShadowChatRootView(
                appState: appState,
                repositoryProvider: repositoryProvider,
                notificationRouter: notificationRouter
            )
        }
    }
}
