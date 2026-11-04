// Fixture (must pass): `.public` is an enum case (Visibility.public), not the `public` keyword (rule 15).
import Foundation

@MainActor @Observable final class ComposerViewModel {
    var visibility: Visibility = .friends
    var isPublic: Bool { visibility == .public }
    func makePublicTapped() { visibility = .public }
}

enum DraftVisibility: String { case `public`, friends }
