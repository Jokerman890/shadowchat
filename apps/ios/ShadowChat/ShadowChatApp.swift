import ShadowChatAppShell
import SwiftUI

@main
@MainActor
struct ShadowChatApp: App {
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
