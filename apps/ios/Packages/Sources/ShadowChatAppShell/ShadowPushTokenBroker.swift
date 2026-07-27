import Foundation
import ShadowCoreContracts
import UIKit
import UserNotifications

enum ShadowPushTokenError: LocalizedError {
    case registrationFailed(String)

    var errorDescription: String? {
        switch self {
        case .registrationFailed(let message):
            "APNs-Registrierung fehlgeschlagen: \(message)"
        }
    }
}

@MainActor
public final class ShadowPushTokenBroker {
    public static let shared = ShadowPushTokenBroker()

    private var token: Data?
    private var continuations: [
        UUID: CheckedContinuation<Data, any Error>
    ] = [:]

    private init() {}

    public func requestDeviceToken() async throws -> Data {
        if let token {
            return token
        }

        let granted = try await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])
        guard granted else {
            throw ShadowServiceError.notificationPermissionDenied
        }

        UIApplication.shared.registerForRemoteNotifications()
        return try await withCheckedThrowingContinuation { continuation in
            continuations[UUID()] = continuation
        }
    }

    public func didRegister(deviceToken: Data) {
        token = deviceToken
        continuations.values.forEach {
            $0.resume(returning: deviceToken)
        }
        continuations.removeAll()
    }

    public func didFailToRegister(error: any Error) {
        let error = ShadowPushTokenError.registrationFailed(
            error.localizedDescription
        )
        continuations.values.forEach {
            $0.resume(throwing: error)
        }
        continuations.removeAll()
    }
}
