import MatrixRustSDK

final nonisolated class MatrixTimelineListener: TimelineListener, Sendable {
    private let receive: @Sendable ([TimelineDiff]) -> Void

    init(receive: @escaping @Sendable ([TimelineDiff]) -> Void) {
        self.receive = receive
    }

    func onUpdate(diff: [TimelineDiff]) {
        receive(diff)
    }
}
