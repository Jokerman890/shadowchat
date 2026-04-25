import SwiftUI

public struct ChatListRoute: View {
    @StateObject private var viewModel: ChatListViewModel

    public init(viewModel: ChatListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ChatListView(
            state: viewModel.state,
            send: viewModel.send
        )
    }
}
