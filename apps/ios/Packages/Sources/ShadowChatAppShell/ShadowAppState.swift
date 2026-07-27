import AuthenticationServices
import Foundation
import Observation
import ShadowCoreContracts

@MainActor
@Observable
public final class ShadowAppState {
    public private(set) var session: ShadowSessionSnapshot
    public private(set) var bridges: [ShadowBridgeSnapshot]
    public private(set) var activePairingSession: ShadowPairingSession?
    public private(set) var authenticationDiscovery: ShadowAuthenticationDiscovery?
    public private(set) var security: ShadowSecuritySnapshot
    public private(set) var verificationUpdate: ShadowDeviceVerificationUpdate?
    public private(set) var generatedRecoveryKey: String?
    public private(set) var pushRegistration: ShadowPushRegistration
    public private(set) var isBusy: Bool
    public private(set) var errorMessage: String?

    private let clientService: any ShadowClientService
    private var securityObservationTask: Task<Void, Never>?
    private var verificationObservationTask: Task<Void, Never>?

    public init(clientService: any ShadowClientService) {
        self.clientService = clientService
        session = ShadowSessionSnapshot(
            state: .launching,
            environment: clientService.runtimeEnvironment
        )
        bridges = []
        security = .unknown
        pushRegistration = .unavailable
        isBusy = false
    }

    public convenience init() {
        self.init(clientService: PreviewShadowClientService())
    }

    public func launch() async {
        guard session.state == .launching else { return }
        isBusy = true
        defer { isBusy = false }

        do {
            if let restored = try await clientService.restoreSession() {
                session = restored
                pushRegistration = await clientService
                    .currentPushRegistration()
                session = try await clientService.startSync()
                startSecurityObservation()
                await refreshBridges()
            } else {
                session = await clientService.currentSession()
            }
        } catch {
            present(error)
            session = ShadowSessionSnapshot(
                state: .failed,
                environment: session.environment
            )
        }
    }

    public func signIn(_ request: ShadowLoginRequest) async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        session = ShadowSessionSnapshot(
            state: .authenticating,
            environment: session.environment
        )
        defer { isBusy = false }

        var createdSession = false
        do {
            session = try await clientService.signIn(request)
            createdSession = true
            pushRegistration = await clientService
                .currentPushRegistration()
            session = try await clientService.startSync()
            startSecurityObservation()
            await refreshBridges()
        } catch {
            if createdSession {
                _ = try? await clientService.signOut(eraseLocalData: true)
                pushRegistration = .unavailable
            }
            present(error)
            session = ShadowSessionSnapshot(
                state: .signedOut,
                environment: session.environment
            )
        }
    }

    public func discoverAuthentication(homeserver: URL) async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            authenticationDiscovery = try await clientService
                .discoverAuthentication(homeserver: homeserver)
        } catch {
            authenticationDiscovery = nil
            present(error)
        }
    }

    public func beginOAuthSignIn(
        homeserver: URL,
        loginHint: String?
    ) async -> ShadowOAuthAuthorization? {
        guard !isBusy else { return nil }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            return try await clientService.beginOAuthSignIn(
                homeserver: homeserver,
                loginHint: loginHint
            )
        } catch {
            present(error)
            return nil
        }
    }

    public func completeOAuthSignIn(callbackURL: URL) async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        session = ShadowSessionSnapshot(
            state: .authenticating,
            environment: session.environment
        )
        defer { isBusy = false }

        var createdSession = false
        do {
            session = try await clientService.completeOAuthSignIn(
                callbackURL: callbackURL
            )
            createdSession = true
            pushRegistration = await clientService
                .currentPushRegistration()
            session = try await clientService.startSync()
            authenticationDiscovery = nil
            startSecurityObservation()
            await refreshBridges()
        } catch {
            if createdSession {
                _ = try? await clientService.signOut(eraseLocalData: true)
                pushRegistration = .unavailable
            }
            present(error)
            session = ShadowSessionSnapshot(
                state: .signedOut,
                environment: session.environment
            )
        }
    }

    public func cancelOAuthSignIn(error: (any Error)? = nil) async {
        await clientService.cancelOAuthSignIn()
        if let error {
            let authenticationError = error as NSError
            let wasCancelled = authenticationError.domain
                == ASWebAuthenticationSessionErrorDomain
                && authenticationError.code
                == ASWebAuthenticationSessionError.canceledLogin.rawValue
            if !wasCancelled {
                present(error)
            }
        }
    }

    public func resetAuthenticationDiscovery() async {
        await clientService.cancelOAuthSignIn()
        authenticationDiscovery = nil
    }

    public func signOut() async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            await clientService.stopSync()
            session = try await clientService.signOut(eraseLocalData: true)
            resetAuthenticatedPresentation()
        } catch {
            session = await clientService.currentSession()
            if session.state == .signedOut {
                resetAuthenticatedPresentation()
            }
            present(error)
        }
    }

    public func refreshBridges() async {
        do {
            bridges = try await clientService.bridgeSnapshots()
        } catch {
            present(error)
        }
    }

    public func beginPairing(_ bridge: ShadowBridgeKind) async {
        guard bridge != .matrix, !isBusy else { return }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            activePairingSession = try await clientService.beginPairing(
                bridge: bridge,
                deviceName: "ShadowChat for iOS"
            )
            await refreshBridges()
        } catch {
            present(error)
        }
    }

    public func confirmPairing() async {
        guard let pairing = activePairingSession, !isBusy else { return }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            _ = try await clientService.confirmPairing(sessionID: pairing.id)
            activePairingSession = nil
            await refreshBridges()
        } catch {
            present(error)
        }
    }

    public func cancelPairing() async {
        guard let pairing = activePairingSession else { return }
        await clientService.cancelPairing(sessionID: pairing.id)
        activePairingSession = nil
        await refreshBridges()
    }

    public func disconnectBridge(_ bridge: ShadowBridgeKind) async {
        guard bridge != .matrix, !isBusy else { return }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            _ = try await clientService.disconnectBridge(
                bridge,
                revokeRemoteSession: true
            )
            await refreshBridges()
        } catch {
            present(error)
        }
    }

    public func refreshSecurity() async {
        do {
            security = try await clientService.securitySnapshot()
        } catch {
            present(error)
        }
    }

    public func beginDeviceVerification() async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        verificationUpdate = nil
        defer { isBusy = false }

        do {
            try await clientService.beginDeviceVerification()
        } catch {
            present(error)
        }
    }

    public func approveDeviceVerification() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }

        do {
            try await clientService.approveDeviceVerification()
        } catch {
            present(error)
        }
    }

    public func declineDeviceVerification() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }

        do {
            try await clientService.declineDeviceVerification()
        } catch {
            present(error)
        }
    }

    public func cancelDeviceVerification() async {
        await clientService.cancelDeviceVerification()
        verificationUpdate = nil
    }

    public func generateRecoveryKey() async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            generatedRecoveryKey = try await clientService
                .generateRecoveryKey(passphrase: nil)
            security = try await clientService.securitySnapshot()
        } catch {
            present(error)
        }
    }

    public func recoverEncryption(recoveryKey: String) async -> Bool {
        guard !isBusy else { return false }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            security = try await clientService.recoverEncryption(
                recoveryKey: recoveryKey
            )
            return true
        } catch {
            present(error)
            return false
        }
    }

    public func clearGeneratedRecoveryKey() {
        generatedRecoveryKey = nil
    }

    public func enablePushNotifications() async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        pushRegistration = ShadowPushRegistration(state: .registering)
        defer { isBusy = false }

        do {
            guard let gatewayURL = configuredPushGatewayURL else {
                throw ShadowServiceError.pushConfigurationMissing
            }
            let deviceToken = try await ShadowPushTokenBroker.shared
                .requestDeviceToken()
            pushRegistration = try await clientService.registerPush(
                deviceToken: deviceToken,
                gatewayURL: gatewayURL
            )
        } catch ShadowServiceError.notificationPermissionDenied {
            pushRegistration = ShadowPushRegistration(state: .denied)
            present(ShadowServiceError.notificationPermissionDenied)
        } catch {
            pushRegistration = ShadowPushRegistration(state: .failed)
            present(error)
        }
    }

    public func disablePushNotifications() async {
        do {
            try await clientService.unregisterPush()
            pushRegistration = .unavailable
        } catch {
            pushRegistration = ShadowPushRegistration(state: .failed)
            present(error)
        }
    }

    public func clearError() {
        errorMessage = nil
    }

    private func present(_ error: any Error) {
        if let localized = error as? any LocalizedError,
           let description = localized.errorDescription {
            errorMessage = description
        } else {
            errorMessage = error.localizedDescription
        }
    }

    private func resetAuthenticatedPresentation() {
        bridges = []
        activePairingSession = nil
        securityObservationTask?.cancel()
        verificationObservationTask?.cancel()
        securityObservationTask = nil
        verificationObservationTask = nil
        security = .unknown
        verificationUpdate = nil
        generatedRecoveryKey = nil
        pushRegistration = .unavailable
    }

    private func startSecurityObservation() {
        securityObservationTask?.cancel()
        verificationObservationTask?.cancel()

        securityObservationTask = Task { [weak self, clientService] in
            let updates = await clientService.securityUpdates()
            for await snapshot in updates {
                guard !Task.isCancelled else { return }
                self?.security = snapshot
            }
        }

        verificationObservationTask = Task { [weak self, clientService] in
            let updates = await clientService.deviceVerificationUpdates()
            for await update in updates {
                guard !Task.isCancelled else { return }
                self?.verificationUpdate = update
            }
        }
    }

    private var configuredPushGatewayURL: URL? {
        guard let value = Bundle.main.object(
            forInfoDictionaryKey: "ShadowPushGatewayURL"
        ) as? String,
        !value.isEmpty,
        let url = URL(string: value),
        url.scheme?.lowercased() == "https" else {
            return nil
        }
        return url
    }
}
