import Foundation
import Observation
import ShadowCoreContracts

@MainActor
@Observable
public final class ShadowAppState {
    public private(set) var session: ShadowSessionSnapshot
    public private(set) var bridges: [ShadowBridgeSnapshot]
    public private(set) var activePairingSession: ShadowPairingSession?
    public private(set) var isBusy: Bool
    public private(set) var errorMessage: String?

    private let clientService: any ShadowClientService

    public init(clientService: any ShadowClientService) {
        self.clientService = clientService
        session = ShadowSessionSnapshot(
            state: .launching,
            environment: clientService.runtimeEnvironment
        )
        bridges = []
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
                session = try await clientService.startSync()
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

        do {
            session = try await clientService.signIn(request)
            session = try await clientService.startSync()
            await refreshBridges()
        } catch {
            present(error)
            session = ShadowSessionSnapshot(
                state: .signedOut,
                environment: session.environment
            )
        }
    }

    public func signOut() async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            await clientService.stopSync()
            session = try await clientService.signOut(eraseLocalData: true)
            bridges = []
            activePairingSession = nil
        } catch {
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
}
