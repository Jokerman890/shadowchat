import SwiftUI

public enum ShadowTrustTone: Equatable {
    case verified
    case standard
    case reduced
}

public enum ShadowColors {
    public static let background = Color(.systemBackground)
    public static let secondaryBackground = Color(.secondarySystemBackground)
    public static let separator = Color(.separator)
    public static let unreadBadge = Color.accentColor

    public static func trustColor(for tone: ShadowTrustTone) -> Color {
        switch tone {
        case .verified:
            return Color.green
        case .standard:
            return Color.secondary
        case .reduced:
            return Color.orange
        }
    }
}
