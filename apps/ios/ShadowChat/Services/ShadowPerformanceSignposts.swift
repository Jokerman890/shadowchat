import OSLog

enum ShadowPerformanceSignposts {
    static let subsystem = "de.shadowchat.ios"
    static let session = OSSignposter(
        subsystem: subsystem,
        category: "Performance.Session"
    )
    static let repository = OSSignposter(
        subsystem: subsystem,
        category: "Performance.Repository"
    )
}
