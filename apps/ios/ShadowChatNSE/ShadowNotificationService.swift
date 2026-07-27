import Foundation
@preconcurrency import UserNotifications

final nonisolated class ShadowNotificationService:
    UNNotificationServiceExtension {
    private let deliveries: ShadowNotificationDeliveryRegistry
    private let processor: ShadowNotificationProcessor

    override init() {
        let deliveries = ShadowNotificationDeliveryRegistry()
        self.deliveries = deliveries
        processor = ShadowNotificationProcessor(deliveries: deliveries)
        super.init()
    }

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler:
            @escaping @Sendable (UNNotificationContent) -> Void
    ) {
        deliveries.register(
            identifier: request.identifier,
            fallback: request.content,
            handler: contentHandler
        )
        Task {
            await processor.process(request)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        deliveries.deliverFallbacks()
    }
}

actor ShadowNotificationProcessor {
    private let deliveries: ShadowNotificationDeliveryRegistry

    init(deliveries: ShadowNotificationDeliveryRegistry) {
        self.deliveries = deliveries
    }

    func process(_ request: UNNotificationRequest) {
        guard let content = request.content.mutableCopy()
            as? UNMutableNotificationContent else {
            deliveries.complete(
                identifier: request.identifier,
                content: request.content
            )
            return
        }

        let roomID = request.content.userInfo["room_id"] as? String
        let eventID = request.content.userInfo["event_id"] as? String

        content.title = "ShadowChat"
        content.body = "Neue verschlüsselte Nachricht"
        content.categoryIdentifier = "SHADOWCHAT_MESSAGE"
        if let roomID {
            content.threadIdentifier = roomID
            content.userInfo["shadowchat_room_id"] = roomID
        }
        if let eventID {
            content.userInfo["shadowchat_event_id"] = eventID
        }

        deliveries.complete(
            identifier: request.identifier,
            content: content
        )
    }
}

final nonisolated class ShadowNotificationDeliveryRegistry:
    @unchecked Sendable {
    private struct Delivery {
        let fallback: UNNotificationContent
        let handler: @Sendable (UNNotificationContent) -> Void
    }

    private let lock = NSLock()
    private var deliveries: [String: Delivery] = [:]

    func register(
        identifier: String,
        fallback: UNNotificationContent,
        handler: @escaping @Sendable (UNNotificationContent) -> Void
    ) {
        lock.withLock {
            deliveries[identifier] = Delivery(
                fallback: fallback,
                handler: handler
            )
        }
    }

    func complete(
        identifier: String,
        content: UNNotificationContent
    ) {
        let delivery = lock.withLock {
            deliveries.removeValue(forKey: identifier)
        }
        delivery?.handler(content)
    }

    func deliverFallbacks() {
        let pending = lock.withLock {
            let pending = Array(deliveries.values)
            deliveries.removeAll()
            return pending
        }
        pending.forEach {
            $0.handler($0.fallback)
        }
    }
}
