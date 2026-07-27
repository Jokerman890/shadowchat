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
        let progressListener = MatrixEncryptionListener<EnableRecoveryProgress> { [weak self] progress in
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
            updateRecovery(ShadowRecoveryState.enabled)
            updateKeyBackup(ShadowKeyBackupState.enabled)
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
            updateRecovery(ShadowRecoveryState.enabled)
            updateKeyBackup(ShadowKeyBackupState.enabled)
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
            listener: MatrixEncryptionListener<VerificationState> { [weak self] state in
                Task {
                    await self?.updateDeviceTrust(state)
                }
            }
        )
        recoveryStateListener = encryption.recoveryStateListener(
            listener: MatrixEncryptionListener<RecoveryState> { [weak self] state in
                Task {
                    await self?.updateRecovery(state)
                }
            }
        )
        backupStateListener = encryption.backupStateListener(
            listener: MatrixEncryptionListener<BackupState> { [weak self] state in
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
            updateRecovery(ShadowRecoveryState.settingUp)
        case .done:
            updateRecovery(ShadowRecoveryState.enabled)
        case .roomKeyUploadError:
            updateKeyBackup(ShadowKeyBackupState.unknown)
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
