import ShadowChatAppShell
import SwiftUI
import UIKit

final class ShadowChatAppDelegate: NSObject, UIApplicationDelegate {
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
}

@main
@MainActor
struct ShadowChatApp: App {
    @UIApplicationDelegateAdaptor(ShadowChatAppDelegate.self)
    private var appDelegate

    private let repositoryProvider: MatrixRepositoryProvider
    @State private var appState: ShadowAppState

    init() {
        let clientService = MatrixRustClientService()
        repositoryProvider = MatrixRepositoryProvider(service: clientService)
        _appState = State(
            initialValue: ShadowAppState(clientService: clientService)
        )
    }

    var body: some Scene {
        WindowGroup {
            ShadowChatRootView(
                appState: appState,
                repositoryProvider: repositoryProvider
            )
        }
    }
}
