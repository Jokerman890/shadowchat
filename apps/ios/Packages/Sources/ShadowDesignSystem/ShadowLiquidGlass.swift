import SwiftUI

public enum ShadowRadii {
    public static let panel: CGFloat = 32
    public static let card: CGFloat = 26
    public static let bubble: CGFloat = 24
    public static let control: CGFloat = 22
}

public var shadowAccentGradient: LinearGradient {
    LinearGradient(
        colors: [
            ShadowColors.accentStart,
            ShadowColors.accentEnd
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

public struct ShadowLiquidBackground<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            content
        }
    }

    private var backgroundColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.07, green: 0.065, blue: 0.10),
                Color(red: 0.11, green: 0.095, blue: 0.19),
                Color(red: 0.075, green: 0.14, blue: 0.22),
                Color(red: 0.14, green: 0.095, blue: 0.16)
            ]
        }

        return [
            ShadowColors.background,
            ShadowColors.lavenderMist,
            ShadowColors.iceBlue,
            ShadowColors.blush
        ]
    }
}

public struct ShadowGlassPanel<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    private let radius: CGFloat
    private let content: Content

    public init(
        radius: CGFloat = ShadowRadii.panel,
        @ViewBuilder content: () -> Content
    ) {
        self.radius = radius
        self.content = content()
    }

    public var body: some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .background(
                LinearGradient(
                    colors: [
                        .white.opacity(colorScheme == .dark ? 0.10 : 0.42),
                        .white.opacity(0.02)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(colorScheme == .dark ? .white.opacity(0.20) : .white.opacity(0.72), lineWidth: 0.8)
            )
            .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
    }
}
