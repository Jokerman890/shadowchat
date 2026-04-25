public protocol ChatListRepository: Sendable {
    func loadChatList() async throws -> [ChatListItemViewState]
}
