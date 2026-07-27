import ShadowChatAppShell
import SwiftUI

@main
@MainActor
struct ShadowChatApp: App {
    @State private var appState = ShadowAppState()

    var body: some Scene {
        WindowGroup {
            ShadowChatRootView(appState: appState)
        }
    }
}
