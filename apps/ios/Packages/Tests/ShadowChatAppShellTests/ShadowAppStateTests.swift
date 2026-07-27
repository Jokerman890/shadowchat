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
