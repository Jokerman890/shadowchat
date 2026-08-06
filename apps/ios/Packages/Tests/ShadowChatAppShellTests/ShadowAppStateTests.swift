import Foundation
import ShadowCoreContracts
import XCTest
@testable import ShadowChatAppShell

@MainActor
final class ShadowAppStateTests: XCTestCase {
    func testLaunchWithoutStoredSessionShowsSignedOutState() async {
        let state = ShadowAppState(clientService: PreviewShadowClientService())

        await state.launch()

        XCTAssertEqual(state.session.state, .signedOut)
        XCTAssertTrue(state.bridges.isEmpty)
    }

    func testPreviewSignInStartsSyncAndLoadsBridgeStates() async throws {
        let state = ShadowAppState(clientService: PreviewShadowClientService())
        await state.launch()

        await state.signIn(
            ShadowLoginRequest(
                homeserver: try XCTUnwrap(URL(string: "https://matrix.org")),
                username: "alice",
                password: "preview",
                deviceDisplayName: "Tests"
            )
        )

        XCTAssertEqual(state.session.state, .syncing)
        XCTAssertEqual(state.session.account?.userID, "@alice:matrix.org")
        XCTAssertEqual(state.bridges.count, 3)
        XCTAssertEqual(
            state.bridges.first { $0.kind == .matrix }?.state,
            .connected
        )
    }

    func testSignInRollsBackSessionWhenSyncStartFails() async throws {
        let service = PreviewShadowClientService(failsSyncStart: true)
        let state = ShadowAppState(clientService: service)
        await state.launch()

        await state.signIn(
            ShadowLoginRequest(
                homeserver: try XCTUnwrap(URL(string: "https://matrix.org")),
                username: "alice",
                password: "preview",
                deviceDisplayName: "Tests"
            )
        )

        let serviceSession = await service.currentSession()
        XCTAssertEqual(state.session.state, .signedOut)
        XCTAssertEqual(serviceSession.state, .signedOut)
        XCTAssertNotNil(state.errorMessage)
    }

    func testLaunchRestoresPersistedPushRegistration() async throws {
        let homeserver = try XCTUnwrap(URL(string: "https://matrix.org"))
        let account = ShadowAccount(
            id: "@alice:matrix.org",
            userID: "@alice:matrix.org",
            displayName: "Alice",
            homeserver: homeserver,
            deviceID: "SHADOWCHAT-TEST"
        )
        let restoredSession = ShadowSessionSnapshot(
            state: .active,
            account: account,
            capabilities: Set(ShadowSessionCapability.allCases),
            environment: .localPreview
        )
        let pushRegistration = ShadowPushRegistration(
            state: .registered,
            registeredAt: Date(timeIntervalSince1970: 1_785_168_000)
        )
        let state = ShadowAppState(
            clientService: PreviewShadowClientService(
                restoredSession: restoredSession,
                pushRegistration: pushRegistration
            )
        )

        await state.launch()

        XCTAssertEqual(state.session.state, .syncing)
        XCTAssertEqual(state.pushRegistration, pushRegistration)
    }

    func testNotificationRouterNormalizesAndConsumesRoomID() {
        let router = ShadowNotificationRouter()

        router.route(toRoomID: "  !room:matrix.org \n")

        XCTAssertEqual(router.pendingRoomID, "!room:matrix.org")
        XCTAssertEqual(router.consumePendingRoomID(), "!room:matrix.org")
        XCTAssertNil(router.pendingRoomID)
    }

    func testBridgePairingRequiresExplicitConfirmation() async throws {
        let state = ShadowAppState(clientService: PreviewShadowClientService())
        await state.launch()
        await state.signIn(
            ShadowLoginRequest(
                homeserver: try XCTUnwrap(URL(string: "https://matrix.org")),
                username: "alice",
                password: "preview",
                deviceDisplayName: "Tests"
            )
        )

        await state.beginPairing(.whatsApp)

        XCTAssertEqual(state.activePairingSession?.bridge, .whatsApp)
        XCTAssertEqual(
            state.bridges.first { $0.kind == .whatsApp }?.state,
            .pairing
        )

        await state.confirmPairing()

        XCTAssertNil(state.activePairingSession)
        XCTAssertEqual(
            state.bridges.first { $0.kind == .whatsApp }?.state,
            .connected
        )
    }
}
