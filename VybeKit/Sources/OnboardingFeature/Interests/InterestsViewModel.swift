import Core
import Foundation

/// O3: pick at least 3 interests. Every tap is written straight into the session's onboarding draft (in memory, not
/// UserDefaults), so going back to Name and photo and returning keeps the choices.
@MainActor @Observable
final class InterestsViewModel {
    static let minimum = 3

    private(set) var selected: Set<InterestOption>
    private let session: SessionStore
    private let router: Router

    /// Cheap: no loading here (ADR 005). Starts from the choices already in the draft.
    init(session: SessionStore, router: Router) {
        self.session = session
        self.router = router
        selected = Set(session.onboardingDraft.interests.compactMap(InterestOption.init(rawValue:)))
    }

    var canContinue: Bool { selected.count >= Self.minimum }

    /// "2 of 3 picked" until the minimum is reached, then nil.
    var progressText: String? {
        canContinue ? nil : InterestsText.progress(selected.count, of: Self.minimum)
    }

    func isSelected(_ interest: InterestOption) -> Bool { selected.contains(interest) }

    func toggle(_ interest: InterestOption) {
        if selected.contains(interest) { selected.remove(interest) } else { selected.insert(interest) }
        // Saved in the list's order, so the draft does not depend on the order of taps.
        session.onboardingDraft.interests = InterestOption.allCases.filter(selected.contains).map(\.rawValue)
    }

    func continueTapped() {
        guard canContinue else { return }
        router.open(.location)
    }
}

/// O3's text, read from OnboardingFeature's own catalog (`bundle: #bundle`, task X-3).
enum InterestsText {
    static var title: String { String(localized: "onboarding.interests.title", bundle: #bundle) }
    static var subtitle: String { String(localized: "onboarding.interests.subtitle", bundle: #bundle) }
    static var continueButton: String { String(localized: "onboarding.interests.continue", bundle: #bundle) }

    /// "2 of 3 picked"
    static func progress(_ count: Int, of minimum: Int) -> String {
        String(localized: "onboarding.interests.progress \(count) \(minimum)", bundle: #bundle)
    }
}
