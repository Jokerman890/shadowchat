import SwiftUI

public enum ShadowMotion {
    public static let pressScale: CGFloat = 0.985
    public static let selectedScale: CGFloat = 1.06

    public static func stateTransition(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.18)
    }

    public static func screenTransition(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.22)
    }
}

public struct ShadowPressScaleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? ShadowMotion.pressScale : 1)
            .animation(ShadowMotion.stateTransition(reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}
