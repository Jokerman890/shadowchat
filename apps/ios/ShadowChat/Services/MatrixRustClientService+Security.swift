import Foundation
import MatrixRustSDK
import ShadowCoreContracts

extension MatrixRustClientService {
    func securitySnapshot() async throws -> ShadowSecuritySnapshot {
        guard let client else {
            throw ShadowServiceError.sessionExpired
        }

        startSecurityObservers(client: client)
        updateDeviceTrust(client.encryption().verificationState())
        return securitySnapshotValue
    }

    func securityUpdates() async -> AsyncStream<ShadowSecuritySnapshot> {
        if let client {
            startSecurityObservers(client: client)
            updateDeviceTrust(client.encryption().verificationState())
        }

        let identifier = UUID()
        let (stream, continuation) = AsyncStream.makeStream(
            of: ShadowSecuritySnapshot.self
        )
        securityContinuations[identifier] = continuation
        continuation.yield(securitySnapshotValue)
        continuation.onTermination = { [weak self] _ in
            Task {
                await self?.removeSecurityContinuation(identifier)
            }
        }
        return stream
    }

    func deviceVerificationUpdates() async
        -> AsyncStream<ShadowDeviceVerificationUpdate> {
        let identifier = UUID()
        let (stream, continuation) = AsyncStream.makeStream(
            of: ShadowDeviceVerificationUpdate.self
        )
        verificationContinuations[identifier] = continuation
        continuation.onTermination = { [weak self] _ in
            Task {
                await self?.removeVerificationContinuation(identifier)
            }
        }
        return stream
    }

    func beginDeviceVerification() async throws {
        guard let client else {
            throw ShadowServiceError.sessionExpired
        }

        await cancelDeviceVerification()

        do {
            let controller = try await client.getSessionVerificationController()
            let delegate = MatrixSessionVerificationDelegate { [weak self] update in
                Task {
                    await self?.receiveVerificationUpdate(update)
                }
            }
            controller.setDelegate(delegate: delegate)
            verificationController = controller
            verificationDelegate = delegate
            try await controller.requestDeviceVerification()
            publishVerification(.requested)
        } catch {
            finishVerification(with: .failed)
            throw mapError(error)
        }
    }

    func approveDeviceVerification() async throws {
        guard let verificationController else {
            throw ShadowServiceError.unsupportedOperation
        }

        do {
            try await verificationController.approveVerification()
        } catch {
            publishVerification(.failed)
            throw mapError(error)
        }
    }

    func declineDeviceVerification() async throws {
        guard let verificationController else {
            throw ShadowServiceError.unsupportedOperation
        }

        do {
            try await verificationController.declineVerification()
        } catch {
            publishVerification(.failed)
            throw mapError(error)
        }
    }

    func cancelDeviceVerification() async {
        guard let verificationController else { return }
        try? await verificationController.cancelVerification()
        finishVerification(with: .cancelled)
    }

    func generateRecoveryKey(passphrase: String?) async throws -> String {
        guard let client else {
            throw ShadowServiceError.sessionExpired
        }

        let normalizedPassphrase = passphrase?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let effectivePassphrase = normalizedPassphrase?.isEmpty == false
            ? normalizedPassphrase
            : nil
        let progressListener = MatrixEncryptionListener<EnableRecoveryProgress> {
            [weak self] progress in
            Task {
                await self?.receiveRecoveryProgress(progress)
            }
        }

        do {
            let recoveryKey = try await client.encryption().enableRecovery(
                waitForBackupsToUpload: false,
                passphrase: effectivePassphrase,
                progressListener: progressListener
            )
            updateRecovery(.enabled)
            updateKeyBackup(.enabled)
            return recoveryKey
        } catch {
            throw mapError(error)
        }
    }

    func recoverEncryption(
        recoveryKey: String
    ) async throws -> ShadowSecuritySnapshot {
        guard let client else {
            throw ShadowServiceError.sessionExpired
        }

        let normalizedKey = recoveryKey
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedKey.isEmpty else {
            throw ShadowServiceError.cryptoUnavailable
        }

        do {
            try await client.encryption().recoverAndFixBackup(
                recoveryKey: normalizedKey
            )
            updateRecovery(.enabled)
            updateKeyBackup(.enabled)
            return securitySnapshotValue
        } catch {
            throw ShadowServiceError.cryptoUnavailable
        }
    }

    func resetSecurityState() {
        verificationController?.setDelegate(delegate: nil)
        verificationController = nil
        verificationDelegate = nil
        verificationStateListener = nil
        recoveryStateListener = nil
        backupStateListener = nil
        securitySnapshotValue = .unknown

        securityContinuations.values.forEach { $0.finish() }
        securityContinuations.removeAll()
        verificationContinuations.values.forEach { $0.finish() }
        verificationContinuations.removeAll()
    }

    private func startSecurityObservers(client: Client) {
        guard verificationStateListener == nil else { return }

        let encryption = client.encryption()
        verificationStateListener = encryption.verificationStateListener(
            listener: MatrixEncryptionListener<VerificationState> {
                [weak self] state in
                Task {
                    await self?.updateDeviceTrust(state)
                }
            }
        )
        recoveryStateListener = encryption.recoveryStateListener(
            listener: MatrixEncryptionListener<RecoveryState> {
                [weak self] state in
                Task {
                    await self?.updateRecovery(state)
                }
            }
        )
        backupStateListener = encryption.backupStateListener(
            listener: MatrixEncryptionListener<BackupState> {
                [weak self] state in
                Task {
                    await self?.updateKeyBackup(state)
                }
            }
        )
    }

    private func updateDeviceTrust(_ state: VerificationState) {
        let mapped: ShadowDeviceTrustState = switch state {
        case .unknown:
            .unknown
        case .unverified:
            .unverified
        case .verified:
            .verified
        }
        securitySnapshotValue = ShadowSecuritySnapshot(
            deviceTrust: mapped,
            recovery: securitySnapshotValue.recovery,
            keyBackup: securitySnapshotValue.keyBackup
        )
        publishSecuritySnapshot()
    }

    private func updateRecovery(_ state: RecoveryState) {
        let mapped: ShadowRecoveryState = switch state {
        case .unknown:
            .unknown
        case .disabled:
            .disabled
        case .incomplete:
            .incomplete
        case .enabled:
            .enabled
        }
        updateRecovery(mapped)
    }

    private func updateRecovery(_ state: ShadowRecoveryState) {
        securitySnapshotValue = ShadowSecuritySnapshot(
            deviceTrust: securitySnapshotValue.deviceTrust,
            recovery: state,
            keyBackup: securitySnapshotValue.keyBackup
        )
        publishSecuritySnapshot()
    }

    private func updateKeyBackup(_ state: BackupState) {
        let mapped: ShadowKeyBackupState = switch state {
        case .unknown:
            .unknown
        case .creating, .enabling:
            .enabling
        case .resuming, .enabled, .downloading:
            .enabled
        case .disabling:
            .disabling
        }
        updateKeyBackup(mapped)
    }

    private func updateKeyBackup(_ state: ShadowKeyBackupState) {
        securitySnapshotValue = ShadowSecuritySnapshot(
            deviceTrust: securitySnapshotValue.deviceTrust,
            recovery: securitySnapshotValue.recovery,
            keyBackup: state
        )
        publishSecuritySnapshot()
    }

    private func receiveRecoveryProgress(_ progress: EnableRecoveryProgress) {
        switch progress {
        case .starting, .creatingBackup, .creatingRecoveryKey, .backingUp:
            updateRecovery(.settingUp)
        case .done:
            updateRecovery(.enabled)
        case .roomKeyUploadError:
            updateKeyBackup(.unknown)
        }
    }

    private func receiveVerificationUpdate(
        _ update: ShadowDeviceVerificationUpdate
    ) async {
        switch update {
        case .accepted:
            publishVerification(update)
            do {
                try await verificationController?.startSasVerification()
            } catch {
                finishVerification(with: .failed)
            }
        case .verified:
            updateDeviceTrust(.verified)
            finishVerification(with: .verified)
        case .cancelled, .failed:
            finishVerification(with: update)
        case .requested, .comparing:
            publishVerification(update)
        }
    }

    private func publishSecuritySnapshot() {
        securityContinuations.values.forEach {
            $0.yield(securitySnapshotValue)
        }
    }

    private func publishVerification(
        _ update: ShadowDeviceVerificationUpdate
    ) {
        verificationContinuations.values.forEach { $0.yield(update) }
    }

    private func finishVerification(
        with update: ShadowDeviceVerificationUpdate
    ) {
        publishVerification(update)
        verificationController?.setDelegate(delegate: nil)
        verificationController = nil
        verificationDelegate = nil
    }

    private func removeSecurityContinuation(_ identifier: UUID) {
        securityContinuations[identifier] = nil
    }

    private func removeVerificationContinuation(_ identifier: UUID) {
        verificationContinuations[identifier] = nil
    }
}

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
