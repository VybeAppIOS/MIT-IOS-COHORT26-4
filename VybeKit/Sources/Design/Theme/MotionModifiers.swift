import SwiftUI
import UIKit

public extension View {
    /// Animates changes to `value` with a `Theme.Motion` token. Reduce Motion turns it into a plain fade.
    func vybeAnimation<Value: Equatable>(_ animation: Animation, value: Value) -> some View {
        modifier(VybeAnimationModifier(animation: animation, value: value))
    }
}

/// Runs `body` inside an animation made from a `Theme.Motion` token, for a tap handler.
/// Outside a View there is no SwiftUI environment, so this asks the system setting directly.
/// That also means the preview-only `vybeReduceMotionOverride` does not reach it; only `vybeAnimation` honours it.
@MainActor
public func withVybeAnimation<Result>(
    _ animation: Animation,
    _ body: () throws -> Result
) rethrows -> Result {
    let resolved = Theme.Motion.resolve(animation, reduceMotion: UIAccessibility.isReduceMotionEnabled)
    return try withAnimation(resolved, body)
}

public extension Theme.Motion {
    /// A panel that slides up from the bottom. With Reduce Motion it only fades.
    static func slideUp(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity)
    }
}

/// SwiftUI's `accessibilityReduceMotion` cannot be set, so a preview cannot switch Reduce Motion on with it.
/// This key lets a preview force the answer. Real devices never set it, so the system setting decides.
private struct ReduceMotionOverrideKey: EnvironmentKey {
    static let defaultValue: Bool? = nil
}

public extension EnvironmentValues {
    /// For previews only: `.environment(\.vybeReduceMotionOverride, true)` shows a view
    /// as it looks with Reduce Motion on.
    /// Never set this in app code; the system setting decides there.
    var vybeReduceMotionOverride: Bool? {
        get { self[ReduceMotionOverrideKey.self] }
        set { self[ReduceMotionOverrideKey.self] = newValue }
    }
}

private struct VybeAnimationModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.vybeReduceMotionOverride) private var override
    let animation: Animation
    let value: Value

    func body(content: Content) -> some View {
        let reduceMotion = override ?? systemReduceMotion
        content.animation(Theme.Motion.resolve(animation, reduceMotion: reduceMotion), value: value)
    }
}

// MARK: - Preview

private struct MotionDemo: View {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.vybeReduceMotionOverride) private var override
    @State private var moved = false
    @State private var showPanel = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            Button {
                moved.toggle()
                showPanel.toggle()
            } label: {
                Text(verbatim: "Toggle")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.onAccent)
                    .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
                    .padding(.horizontal, Theme.Spacing.large)
                    .background(Theme.Color.accent, in: .rect(cornerRadius: Theme.Radius.medium))
            }
            Circle()
                .fill(Theme.Color.accent)
                .frame(width: Theme.Spacing.huge, height: Theme.Spacing.huge)
                .offset(x: moved ? 200 : 0)
                .vybeAnimation(Theme.Motion.standard, value: moved)
                .accessibilityHidden(true)
            if showPanel {
                Text(verbatim: "Slides up, or fades with Reduce Motion")
                    .font(Theme.Font.body)
                    .padding(Theme.Spacing.large)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Color.surfaceRaised, in: .rect(cornerRadius: Theme.Radius.medium))
                    .transition(Theme.Motion.slideUp(reduceMotion: override ?? systemReduceMotion))
            }
            Spacer()
        }
        .vybeAnimation(Theme.Motion.standard, value: showPanel)
        .vybeHaptic(.selection, trigger: moved)
        .padding(Theme.Spacing.large)
        .background(Theme.Color.surface)
    }
}

#Preview("Motion, normal") {
    MotionDemo()
}

#Preview("Motion, Reduce Motion on") {
    MotionDemo()
        .environment(\.vybeReduceMotionOverride, true)
}
