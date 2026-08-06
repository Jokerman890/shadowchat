import AuthenticationServices
import Foundation
import UIKit

enum ShadowOAuthPresenterError: LocalizedError {
    case missingPresentationWindow
    case missingCallback

    var errorDescription: String? {
        switch self {
        case .missingPresentationWindow:
            "Das sichere Anmeldefenster konnte nicht geöffnet werden."
        case .missingCallback:
            "Der Identitätsanbieter hat keine gültige Antwort geliefert."
        }
    }
}

@MainActor
final class ShadowOAuthPresenter: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var session: ASWebAuthenticationSession?
    private var presentationWindow: UIWindow?

    func authenticate(
        using authorizationURL: URL,
        callbackScheme: String
    ) async throws -> URL {
        guard let window = activeWindow else {
            throw ShadowOAuthPresenterError.missingPresentationWindow
        }
        presentationWindow = window

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authorizationURL,
                callbackURLScheme: callbackScheme
            ) { [weak self] callbackURL, error in
                self?.session = nil
                self?.presentationWindow = nil

                if let error {
                    continuation.resume(throwing: error)
                } else if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(
                        throwing: ShadowOAuthPresenterError.missingCallback
                    )
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.session = session

            if !session.start() {
                self.session = nil
                self.presentationWindow = nil
                continuation.resume(
                    throwing: ShadowOAuthPresenterError.missingPresentationWindow
                )
            }
        }
    }

    func cancel() {
        session?.cancel()
        session = nil
        presentationWindow = nil
    }

    func presentationAnchor(
        for session: ASWebAuthenticationSession
    ) -> ASPresentationAnchor {
        presentationWindow ?? UIWindow()
    }

    private var activeWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }
}
