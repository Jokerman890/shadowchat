import ShadowChatListFeature
import ShadowDesignSystem
import SwiftUI

public struct ShadowChatRootView: View {
    @StateObject private var chatListViewModel: ChatListViewModel

    public init() {
        _chatListViewModel = StateObject(
            wrappedValue: ChatListViewModel(repository: EmptyChatListRepository())
        )
    }

    public var body: some View {
        NavigationStack {
            ChatListRoute(viewModel: chatListViewModel)
        }
        .background(ShadowColors.background)
    }
}

private struct EmptyChatListRepository: ChatListRepository {
    func loadChatList() async throws -> [ChatListItemViewState] {
        []
    }
}

#if DEBUG
#Preview {
    ShadowChatRootView()
}
#endif
