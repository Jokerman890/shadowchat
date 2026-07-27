import SwiftUI

public enum ShadowTrustTone: Equatable {
    case verified
    case standard
    case reduced
}

public enum ShadowColors {
    public static let whatsAppGreen = Color(red: 37 / 255, green: 211 / 255, blue: 102 / 255)
    public static let whatsAppTeal = Color(red: 18 / 255, green: 140 / 255, blue: 126 / 255)
    public static let oledBlack = Color.black
    public static let background = Color(red: 0.035, green: 0.043, blue: 0.047)
    public static let lavenderMist = Color(red: 0.06, green: 0.10, blue: 0.10)
    public static let iceBlue = Color(red: 0.04, green: 0.13, blue: 0.12)
    public static let blush = Color(red: 0.06, green: 0.075, blue: 0.07)
    public static let secondaryBackground = Color.white.opacity(0.08)
    public static let separator = Color.white.opacity(0.62)
    public static let unreadBadge = whatsAppGreen
    public static let accentStart = whatsAppGreen
    public static let accentEnd = whatsAppTeal
    public static let deepText = Color(.label)
    public static let softText = Color(.secondaryLabel)
    public static let incomingBubble = Color(red: 0.11, green: 0.125, blue: 0.13)
    public static let outgoingBubble = Color(red: 0.025, green: 0.30, blue: 0.24)
    public static let lightBackgroundStart = Color(red: 0.94, green: 0.98, blue: 0.96)
    public static let lightBackgroundMiddle = Color(red: 0.88, green: 0.96, blue: 0.92)
    public static let lightBackgroundEnd = Color(red: 0.92, green: 0.98, blue: 0.97)
    public static let lightCanvas = Color.white

    public static func trustColor(for tone: ShadowTrustTone) -> Color {
        switch tone {
        case .verified:
            return whatsAppGreen
        case .standard:
            return Color(red: 0.57, green: 0.54, blue: 0.65)
        case .reduced:
            return Color(red: 1.0, green: 0.62, blue: 0.18)
        }
    }
}
