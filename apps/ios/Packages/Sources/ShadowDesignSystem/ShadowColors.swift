import SwiftUI

public enum ShadowTrustTone: Equatable {
    case verified
    case standard
    case reduced
}

public enum ShadowColors {
    public static let background = Color(red: 1.0, green: 0.985, blue: 1.0)
    public static let lavenderMist = Color(red: 0.955, green: 0.935, blue: 1.0)
    public static let iceBlue = Color(red: 0.92, green: 0.965, blue: 1.0)
    public static let blush = Color(red: 1.0, green: 0.935, blue: 0.975)
    public static let secondaryBackground = Color.white.opacity(0.72)
    public static let separator = Color.white.opacity(0.62)
    public static let unreadBadge = Color(red: 0.40, green: 0.34, blue: 1.0)
    public static let accentStart = Color(red: 0.48, green: 0.38, blue: 1.0)
    public static let accentEnd = Color(red: 0.22, green: 0.65, blue: 1.0)
    public static let deepText = Color(.label)
    public static let softText = Color(.secondaryLabel)
    public static let incomingBubble = Color.white.opacity(0.82)
    public static let outgoingBubble = Color(red: 0.93, green: 0.905, blue: 1.0).opacity(0.94)

    public static func trustColor(for tone: ShadowTrustTone) -> Color {
        switch tone {
        case .verified:
            return Color(red: 0.13, green: 0.71, blue: 0.45)
        case .standard:
            return Color(red: 0.57, green: 0.54, blue: 0.65)
        case .reduced:
            return Color(red: 1.0, green: 0.62, blue: 0.18)
        }
    }
}
