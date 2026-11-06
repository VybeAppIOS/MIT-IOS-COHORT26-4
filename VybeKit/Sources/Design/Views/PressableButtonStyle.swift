import SwiftUI

/// The press feel of every Vybe button: it shrinks to 96% while a finger is down and springs back (the quick motion
/// token). With Reduce Motion on there is no scale at all. It also draws the three looks the buttons use, because a
/// system `.bordered` or `.borderedProminent` style cannot be combined with a custom one.
public struct PressableButtonStyle: ButtonStyle {
    public enum Look: Sendable {
        /// No fill: a chip or an icon draws its own background.
        case plain
        /// Solid tint fill with `onAccent` text (the main action).
        case prominent
        /// Soft tint wash with tint-coloured text (the quiet action).
        case tinted
    }

    private let look: Look
    private let tint: Color
    /// `nil` draws a capsule.
    private let cornerRadius: CGFloat?

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.vybeReduceMotionOverride) private var reduceMotionOverride

    public init(look: Look = .plain, tint: Color = Theme.Color.accent, cornerRadius: CGFloat? = nil) {
        self.look = look
        self.tint = tint
        self.cornerRadius = cornerRadius
    }

    public func makeBody(configuration: Configuration) -> some View {
        let reduceMotion = reduceMotionOverride ?? systemReduceMotion
        let pressed = configuration.isPressed && !reduceMotion
        return configuration.label
            .padding(.horizontal, look == .plain ? 0 : Theme.Spacing.large)
            .padding(.vertical, look == .plain ? 0 : Theme.Spacing.small - Theme.Spacing.tiny / 4)
            .foregroundStyle(foreground)
            .background(fill, in: shape)
            .contentShape(shape)
            .opacity(isEnabled || look == .prominent ? 1 : 0.5)
            .scaleEffect(pressed ? 0.96 : 1)
            .animation(Theme.Motion.resolve(Theme.Motion.quick, reduceMotion: reduceMotion),
                       value: configuration.isPressed)
    }

    private var shape: AnyShape {
        cornerRadius.map { AnyShape(RoundedRectangle(cornerRadius: $0, style: .continuous)) } ?? AnyShape(Capsule())
    }

    private var foreground: Color {
        switch look {
        case .plain: Theme.Color.textPrimary
        case .prominent: Theme.Color.onAccent
        case .tinted: tint
        }
    }

    private var fill: Color {
        switch look {
        case .plain: .clear
        case .prominent: isEnabled ? tint : Theme.Color.separator
        case .tinted: tint.opacity(0.15)
        }
    }
}

#Preview("PressableButtonStyle") {
    VStack(spacing: Theme.Spacing.large) {
        Button("Prominent") {}.buttonStyle(PressableButtonStyle(look: .prominent, cornerRadius: Theme.Radius.medium))
        Button("Tinted") {}.buttonStyle(PressableButtonStyle(look: .tinted, cornerRadius: Theme.Radius.medium))
        Button("Pill") {}.buttonStyle(PressableButtonStyle(look: .tinted))
        Button("Disabled") {}.buttonStyle(PressableButtonStyle(look: .prominent)).disabled(true)
    }
    .padding(Theme.Spacing.large)
    .background(Theme.Color.surface)
}
