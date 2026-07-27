import SwiftUI

public struct RoomTimelineRoute: View {
    @StateObject private var viewModel: RoomTimelineViewModel

    public init(viewModel: RoomTimelineViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        RoomTimelineView(
            state: viewModel.state,
            draft: viewModel.draft,
            isSending: viewModel.isSending,
            sendErrorMessage: viewModel.sendErrorMessage,
            send: viewModel.send
        )
    }
}
