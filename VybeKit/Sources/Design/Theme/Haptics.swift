import SwiftUI

/// The haptics Vybe uses, each with its Apple meaning (docs/MOTION.md section 3). Real iPhone only.
/// The case names follow MOTION.md and Apple's `SensoryFeedback`, so `stop` stays as written there.
public enum VybeHaptic: Sendable {
    /// Filter chips and pin selection.
    case selection
    /// Start Hangout.
    case start
    /// End Hangout.
    case stop
    /// Mark visited.
    case success
    /// Liking. Give it a trigger that changes only when something is liked, not when it is unliked.
    case like

    var feedback: SensoryFeedback {
        switch self {
        case .selection: .selection
        case .start: .start
        case .stop: .stop
        case .success: .success
        case .like: .impact(weight: .light)
        }
    }
}

public extension View {
    /// Plays `haptic` each time `trigger` changes.
    func vybeHaptic<Trigger: Equatable>(_ haptic: VybeHaptic, trigger: Trigger) -> some View {
        sensoryFeedback(haptic.feedback, trigger: trigger)
    }
}
