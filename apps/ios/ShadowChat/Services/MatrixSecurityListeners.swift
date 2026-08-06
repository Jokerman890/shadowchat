import MatrixRustSDK
import ShadowCoreContracts

final nonisolated class MatrixEncryptionListener<Value: Sendable>:
    @unchecked Sendable {
    private let receive: @Sendable (Value) -> Void

    init(receive: @escaping @Sendable (Value) -> Void) {
        self.receive = receive
    }

    func send(_ value: Value) {
        receive(value)
    }
}

extension MatrixEncryptionListener: VerificationStateListener
    where Value == VerificationState {
    func onUpdate(status: VerificationState) {
        send(status)
    }
}

extension MatrixEncryptionListener: RecoveryStateListener
    where Value == RecoveryState {
    func onUpdate(status: RecoveryState) {
        send(status)
    }
}

extension MatrixEncryptionListener: BackupStateListener
    where Value == BackupState {
    func onUpdate(status: BackupState) {
        send(status)
    }
}

extension MatrixEncryptionListener: EnableRecoveryProgressListener
    where Value == EnableRecoveryProgress {
    func onUpdate(status: EnableRecoveryProgress) {
        send(status)
    }
}

final nonisolated class MatrixSessionVerificationDelegate:
    SessionVerificationControllerDelegate,
    @unchecked Sendable {
    private let receive: @Sendable (ShadowDeviceVerificationUpdate) -> Void

    init(
        receive: @escaping @Sendable (ShadowDeviceVerificationUpdate) -> Void
    ) {
        self.receive = receive
    }

    func didReceiveVerificationRequest(
        details: MatrixRustSDK.SessionVerificationRequestDetails
    ) {
        receive(.requested)
    }

    func didReceiveVerificationData(data: SessionVerificationData) {
        guard case .emojis(let emojis, _) = data else { return }
        receive(
            .comparing(
                emojis.map {
                    ShadowVerificationEmoji(
                        symbol: $0.symbol(),
                        description: $0.description()
                    )
                }
            )
        )
    }

    func didAcceptVerificationRequest() {
        receive(.accepted)
    }

    func didStartSasVerification() {
        // Emoji data is the next user-visible transition.
    }

    func didFail() {
        receive(.failed)
    }

    func didCancel() {
        receive(.cancelled)
    }

    func didFinish() {
        receive(.verified)
    }
}
