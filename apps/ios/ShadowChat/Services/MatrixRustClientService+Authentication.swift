import Foundation
import MatrixRustSDK
import ShadowCoreContracts

struct MatrixPendingAuthentication {
    let homeserver: URL
    let client: Client
    let directories: MatrixSessionDirectories
    let passphrase: String
    var authorizationData: OAuthAuthorizationData?
}

extension MatrixRustClientService {
    func discoverAuthentication(
        homeserver: URL
    ) async throws -> ShadowAuthenticationDiscovery {
        guard homeserver.scheme?.lowercased() == "https",
              homeserver.host != nil else {
            throw ShadowServiceError.invalidHomeserver
        }

        await cancelOAuthSignIn()
        let directories = try MatrixSessionDirectories.create()
        let passphrase = try SecurePassphraseGenerator.make()

        do {
            let authenticationClient = try await makeAuthenticationClient(
                homeserver: homeserver,
                directories: directories,
                passphrase: passphrase
            )
            let details = await authenticationClient.homeserverLoginDetails()
            let mode: ShadowAuthenticationMode
            if details.supportsOauthLogin() {
                mode = .oauth
            } else if details.supportsPasswordLogin() {
                mode = .password
            } else {
                mode = .unsupported
            }
            let discovery = ShadowAuthenticationDiscovery(
                homeserver: homeserver,
                mode: mode,
                supportsAccountCreation: details
                    .supportedOauthPrompts()
                    .contains(.create)
            )
            pendingAuthentication = MatrixPendingAuthentication(
                homeserver: homeserver,
                client: authenticationClient,
                directories: directories,
                passphrase: passphrase,
                authorizationData: nil
            )
            return discovery
        } catch {
            try? directories.remove()
            throw mapError(error)
        }
    }

    func beginOAuthSignIn(
        homeserver: URL,
        loginHint: String?
    ) async throws -> ShadowOAuthAuthorization {
        if pendingAuthentication?.homeserver != homeserver {
            _ = try await discoverAuthentication(homeserver: homeserver)
        }
        guard var authentication = pendingAuthentication else {
            throw ShadowServiceError.serverDiscoveryFailed
        }

        let details = await authentication.client.homeserverLoginDetails()
        guard details.supportsOauthLogin() else {
            throw ShadowServiceError.unsupportedOperation
        }

        do {
            let authorizationData = try await authentication.client.urlForOauth(
                oauthConfiguration: oauthConfiguration,
                prompt: .consent,
                loginHint: loginHint?.nonEmpty,
                deviceId: nil,
                additionalScopes: nil
            )
            guard let authorizationURL = URL(string: authorizationData.loginUrl()) else {
                throw ShadowServiceError.serverDiscoveryFailed
            }
            authentication.authorizationData = authorizationData
            pendingAuthentication = authentication
            return ShadowOAuthAuthorization(
                authorizationURL: authorizationURL,
                callbackScheme: Self.oauthCallbackScheme
            )
        } catch {
            throw mapError(error)
        }
    }

    func completeOAuthSignIn(
        callbackURL: URL
    ) async throws -> ShadowSessionSnapshot {
        guard let authentication = pendingAuthentication else {
            throw ShadowServiceError.cancelled
        }

        do {
            try await authentication.client.loginWithOauthCallback(
                callbackUrl: callbackURL.absoluteString
            )
            let snapshot = try activateAuthenticatedClient(
                client: authentication.client,
                directories: authentication.directories,
                passphrase: authentication.passphrase
            )
            pendingAuthentication = nil
            return snapshot
        } catch {
            throw mapError(error)
        }
    }

    func cancelOAuthSignIn() async {
        guard let authentication = pendingAuthentication else {
            return
        }
        if let authorizationData = authentication.authorizationData {
            await authentication.client.abortOauthAuth(
                authorizationData: authorizationData
            )
        }
        try? authentication.directories.remove()
        pendingAuthentication = nil
    }

    func activateAuthenticatedClient(
        client authenticatedClient: Client,
        directories: MatrixSessionDirectories,
        passphrase: String
    ) throws -> ShadowSessionSnapshot {
        let snapshot = try makeSessionSnapshot(
            client: authenticatedClient,
            state: .active,
            lastSyncAt: nil
        )
        let token = MatrixRestorationToken(
            session: try authenticatedClient.session(),
            directories: directories,
            storePassphrase: passphrase
        )
        try keychain.save(token)

        client = authenticatedClient
        activeToken = token
        sessionSnapshot = snapshot
        return snapshot
    }

    private var oauthConfiguration: MatrixRustSDK.OAuthConfiguration {
        let projectURL = "https://github.com/Jokerman890/shadowchat"
        return MatrixRustSDK.OAuthConfiguration(
            clientName: "ShadowChat",
            redirectUri: Self.oauthCallbackURL.absoluteString,
            clientUri: projectURL,
            logoUri: "https://github.com/Jokerman890.png",
            tosUri: projectURL,
            policyUri: projectURL,
            staticRegistrations: [:]
        )
    }

    private static let oauthCallbackScheme = "de.shadowchat.ios"
    private static let oauthCallbackURL = URL(
        string: "\(oauthCallbackScheme)://oauth/callback"
    )!
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
