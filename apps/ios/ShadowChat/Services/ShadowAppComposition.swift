import ShadowChatAppShell

@MainActor
struct ShadowAppComposition {
    let appState: ShadowAppState
    let repositoryProvider: any ShadowRepositoryProvider
    let notificationRouter: ShadowNotificationRouter

    static func live() -> ShadowAppComposition {
        let clientService = MatrixRustClientService()
        return ShadowAppComposition(
            appState: ShadowAppState(clientService: clientService),
            repositoryProvider: MatrixRepositoryProvider(
                service: clientService
            ),
            notificationRouter: .shared
        )
    }
}
