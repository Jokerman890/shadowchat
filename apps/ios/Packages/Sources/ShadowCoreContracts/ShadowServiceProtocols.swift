import Foundation

public protocol ShadowSessionService: Actor {
    nonisolated var runtimeEnvironment: ShadowRuntimeEnvironment { get }

    func restoreSession() async throws -> ShadowSessionSnapshot?
    func signIn(_ request: ShadowLoginRequest) async throws -> ShadowSessionSnapshot
    func currentSession() async -> ShadowSessionSnapshot
    func startSync() async throws -> ShadowSessionSnapshot
    func stopSync() async
    func signOut(eraseLocalData: Bool) async throws -> ShadowSessionSnapshot
}

public protocol ShadowBridgeService: Actor {
    func bridgeSnapshots() async throws -> [ShadowBridgeSnapshot]
    func beginPairing(
        bridge: ShadowBridgeKind,
        deviceName: String
    ) async throws -> ShadowPairingSession
    func confirmPairing(sessionID: UUID) async throws -> ShadowBridgeSnapshot
    func cancelPairing(sessionID: UUID) async
    func disconnectBridge(
        _ bridge: ShadowBridgeKind,
        revokeRemoteSession: Bool
    ) async throws -> ShadowBridgeSnapshot
    func puppets(for bridge: ShadowBridgeKind) async throws -> [ShadowUserPuppet]
}

public protocol ShadowClientService: ShadowSessionService, ShadowBridgeService {}
