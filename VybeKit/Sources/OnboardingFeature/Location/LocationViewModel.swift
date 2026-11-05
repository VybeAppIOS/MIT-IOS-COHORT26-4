import Core
import Foundation
import Models

/// O4: explain why we ask for location, then ask ("While Using the App" only, never "Always"). If the person says
/// "Not now", has denied it before, or no system prompt appears, they pick an area instead (Kothrud by default).
/// Finishing saves the onboarding draft and switches the app to the tabs.
///
/// `requestWhenInUse()` does not report the answer, so the screen works it out: when the system prompt shows, the app
/// goes inactive; when it comes back, the answer is read from `authorization`. If no prompt appears within a moment
/// (no permission text in the project yet, task X-9), the area picker opens.
@MainActor @Observable
final class LocationViewModel {
    enum Step: Equatable {
        case explain
        /// Asked; waiting for the system prompt and the person's answer.
        case waitingForAnswer
        /// Choosing an area. `couldNotAsk` adds a note when no prompt appeared.
        case pickArea(couldNotAsk: Bool)
    }

    /// One area to choose from: its saved ID ("kothrud") and its name ("Kothrud").
    struct AreaOption: Equatable, Identifiable, Sendable {
        let id: String
        let name: String
    }

    /// The default area (task SC-O4), offered even when no Places load.
    static let defaultArea = AreaOption(id: "kothrud", name: "Kothrud")
    /// How long to wait for the system prompt before assuming it cannot appear.
    static let promptWait = Duration.seconds(1)

    private(set) var step: Step = .explain
    private(set) var areas: [AreaOption] = [defaultArea]
    private(set) var selectedAreaID = defaultArea.id
    private(set) var isFinished = false

    private let location: any LocationService
    private let hangouts: any HangoutRepository
    private let places: any PlaceRepository
    private let session: SessionStore
    private let router: Router
    private let sleep: @Sendable (Duration) async -> Void
    private var promptAppeared = false

    /// Cheap: no loading here (ADR 005). `sleep` is injected so tests do not wait a real second.
    init(
        location: any LocationService, hangouts: any HangoutRepository, places: any PlaceRepository,
        session: SessionStore, router: Router,
        sleep: @escaping @Sendable (Duration) async -> Void = { try? await Task.sleep(for: $0) }
    ) {
        self.location = location
        self.hangouts = hangouts
        self.places = places
        self.session = session
        self.router = router
        self.sleep = sleep
    }

    // MARK: Areas

    /// The areas of the Places in the published Hangouts, Kothrud first and always present. There is no
    /// "list the areas" call yet (Lohitaksh: an `areas()` in `PlaceRepository`), so they are read from the Places.
    func loadAreas() async {
        let found = (try? await hangouts.hangouts(near: nil, filters: HangoutFilters())) ?? []
        var names: [String] = []
        for hangout in found {
            for place in (try? await places.spots(for: hangout)) ?? [] where !names.contains(place.area) {
                names.append(place.area)
            }
        }
        let options = names.map { AreaOption(id: Self.areaID(for: $0), name: $0) }
        let others = options.filter { $0.id != Self.defaultArea.id }.sorted { $0.name < $1.name }
        areas = [options.first { $0.id == Self.defaultArea.id } ?? Self.defaultArea] + others
    }

    func selectArea(_ id: String) { selectedAreaID = id }

    /// "Kothrud" → "kothrud", "Model Colony" → "model-colony" (the form `AppSettings.selectedAreaID` uses).
    static func areaID(for name: String) -> String {
        name.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: "-")
    }

    // MARK: Asking

    func allowTapped() async {
        switch location.authorization {
        case .whenInUse, .always:
            finish(areaID: nil)                 // already allowed: no prompt, no area needed
            return
        case .denied, .restricted:
            step = .pickArea(couldNotAsk: false)   // iOS will not ask again
            return
        case .notDetermined:
            break
        }
        step = .waitingForAnswer
        promptAppeared = false
        location.requestWhenInUse()
        await sleep(Self.promptWait)
        if step == .waitingForAnswer && !promptAppeared {
            step = .pickArea(couldNotAsk: true)
        }
    }

    func notNowTapped() { step = .pickArea(couldNotAsk: false) }

    /// The app went inactive while waiting: the system prompt is on screen.
    func appBecameInactive() {
        if step == .waitingForAnswer { promptAppeared = true }
    }

    /// The app is active again after the prompt: read the answer.
    func appBecameActive() {
        guard step == .waitingForAnswer, promptAppeared else { return }
        if location.authorization.isAuthorized {
            finish(areaID: nil)
        } else {
            step = .pickArea(couldNotAsk: false)
        }
    }

    // MARK: Finishing

    /// "Done" on the area picker.
    func doneTapped() { finish(areaID: selectedAreaID) }

    private func finish(areaID: String?) {
        guard !isFinished else { return }
        isFinished = true
        session.onboardingDraft.areaID = areaID
        session.completeOnboarding()            // saves the draft and the onboarding flag (it persists)
        router.reset()                          // RootView switches to the tabs
    }
}

/// O4's text, read from OnboardingFeature's own catalog (`bundle: #bundle`, task X-3).
enum LocationText {
    static var title: String { String(localized: "onboarding.location.title", bundle: #bundle) }
    static var why: String { String(localized: "onboarding.location.why", bundle: #bundle) }
    static var allow: String { String(localized: "onboarding.location.allow", bundle: #bundle) }
    static var notNow: String { String(localized: "onboarding.location.notNow", bundle: #bundle) }
    static var pickTitle: String { String(localized: "onboarding.location.pickTitle", bundle: #bundle) }
    static var pickWhy: String { String(localized: "onboarding.location.pickWhy", bundle: #bundle) }
    static var couldNotAsk: String { String(localized: "onboarding.location.couldNotAsk", bundle: #bundle) }
    static var done: String { String(localized: "onboarding.location.done", bundle: #bundle) }
}
