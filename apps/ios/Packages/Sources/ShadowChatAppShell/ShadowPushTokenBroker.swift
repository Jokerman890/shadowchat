import Foundation
import ShadowCoreContracts
import UIKit
import UserNotifications

enum ShadowPushTokenError: LocalizedError {
    case registrationFailed(String)
    case registrationTimedOut

    var errorDescription: String? {
        switch self {
        case .registrationFailed(let message):
            return "APNs-Registrierung fehlgeschlagen: \(message)"
        case .registrationTimedOut:
            return "APNs hat nicht rechtzeitig auf die Registrierung geantwortet."
        }
    }
}

@MainActor
public final class ShadowPushTokenBroker {
    public static let shared = ShadowPushTokenBroker()

    private struct PendingRegistration {
        let continuation: CheckedContinuation<Data, any Error>
        let timeoutTask: Task<Void, Never>
    }

    private var token: Data?
    private var pendingRegistrations: [UUID: PendingRegistration] = [:]

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

        let registrationID = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let timeoutTask = Task { @MainActor [weak self] in
                    do {
                        try await Task.sleep(for: .seconds(20))
                    } catch {
                        return
                    }
                    self?.complete(
                        registrationID,
                        with: .failure(
                            ShadowPushTokenError.registrationTimedOut
                        )
                    )
                }
                pendingRegistrations[registrationID] = PendingRegistration(
                    continuation: continuation,
                    timeoutTask: timeoutTask
                )
                if Task.isCancelled {
                    complete(
                        registrationID,
                        with: .failure(CancellationError())
                    )
                } else {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.complete(
                    registrationID,
                    with: .failure(CancellationError())
                )
            }
        }
    }

    public func didRegister(deviceToken: Data) {
        token = deviceToken
        for registrationID in Array(pendingRegistrations.keys) {
            complete(registrationID, with: .success(deviceToken))
        }
    }

    public func didFailToRegister(error: any Error) {
        let registrationError = ShadowPushTokenError.registrationFailed(
            error.localizedDescription
        )
        for registrationID in Array(pendingRegistrations.keys) {
            complete(registrationID, with: .failure(registrationError))
        }
    }

    private func complete(
        _ registrationID: UUID,
        with result: Result<Data, any Error>
    ) {
        guard let registration = pendingRegistrations.removeValue(
            forKey: registrationID
        ) else {
            return
        }
        registration.timeoutTask.cancel()
        registration.continuation.resume(with: result)
    }
}
