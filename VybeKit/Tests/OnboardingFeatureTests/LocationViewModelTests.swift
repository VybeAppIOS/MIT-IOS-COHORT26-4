import Core
import Foundation
import Models
import Synchronization
import Testing
@testable import OnboardingFeature

/// A location service whose answer the test sets. `Mutex` keeps it safe to share across threads (no unchecked
/// Sendable).
private final class FakeLocation: LocationService {
    private let state: Mutex<LocationAuthorization>

    init(_ authorization: LocationAuthorization) { state = Mutex(authorization) }

    var authorization: LocationAuthorization { state.withLock { $0 } }
    func answer(_ authorization: LocationAuthorization) { state.withLock { $0 = authorization } }
    func updates() -> AsyncStream<LocationSample> { AsyncStream { $0.finish() } }
    func requestWhenInUse() {}
}

/// Holds the injected `sleep` until the test opens it, so the test can act while the screen waits for the prompt.
private actor Gate {
    private var isOpen = false
    private var waiting: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { waiting.append($0) }
    }

    func open() {
        isOpen = true
        waiting.forEach { $0.resume() }
        waiting = []
    }
}

@MainActor
struct LocationViewModelTests {
    private func makeViewModel(
        _ location: FakeLocation, session: SessionStore? = nil, router: Router = Router(),
        sleep: @escaping @Sendable (Duration) async -> Void = { _ in }
    ) -> (LocationViewModel, SessionStore) {
        let deps = AppDependencies.preview()
        let session = session ?? deps.session
        let viewModel = LocationViewModel(
            location: location, hangouts: deps.hangouts, places: deps.places, session: session, router: router,
            sleep: sleep)
        return (viewModel, session)
    }

    private func freshSession() -> (SessionStore, AppSettings) {
        let settings = AppSettings(suiteName: "vybe.test.\(UUID().uuidString)")
        return (SessionStore(settings: settings, currentUser: SampleData.signedInUser), settings)
    }

    // MARK: The task's tests

    @Test func deniedGoesToTheAreaPickerThenCompletes() async {
        let router = Router()
        router.setOnboarding(true)
        let (viewModel, session) = makeViewModel(FakeLocation(.denied), session: freshSession().0, router: router)
        await viewModel.allowTapped()
        #expect(viewModel.step == .pickArea(couldNotAsk: false))
        #expect(viewModel.selectedAreaID == "kothrud")
        viewModel.doneTapped()
        #expect(session.onboardingDone)
        #expect(!router.isOnboarding)
        #expect(router.path(for: .onboarding).isEmpty)
    }

    @Test func alreadyAllowedCompletesWithoutThePicker() async {
        let (viewModel, session) = makeViewModel(FakeLocation(.whenInUse), session: freshSession().0)
        await viewModel.allowTapped()
        #expect(viewModel.isFinished)
        #expect(session.onboardingDone)
    }

    @Test func allowingInTheSystemPromptCompletes() async {
        let location = FakeLocation(.notDetermined)
        let gate = Gate()
        let (viewModel, session) = makeViewModel(location, session: freshSession().0, sleep: { _ in await gate.wait() })
        let asking = Task { await viewModel.allowTapped() }
        while viewModel.step != .waitingForAnswer { await Task.yield() }
        viewModel.appBecameInactive()
        location.answer(.whenInUse)
        viewModel.appBecameActive()
        await gate.open()
        await asking.value
        #expect(session.onboardingDone)
    }

    @Test func theOnboardingFlagPersists() async {
        let (session, settings) = freshSession()
        let (viewModel, _) = makeViewModel(FakeLocation(.denied), session: session)
        await viewModel.allowTapped()
        viewModel.doneTapped()
        let afterRelaunch = SessionStore(settings: settings)
        #expect(afterRelaunch.onboardingDone)
        #expect(settings.selectedAreaID == "kothrud")
    }

    // MARK: The other paths

    @Test func notNowGoesToTheAreaPicker() {
        let (viewModel, _) = makeViewModel(FakeLocation(.notDetermined))
        viewModel.notNowTapped()
        #expect(viewModel.step == .pickArea(couldNotAsk: false))
    }

    @Test func noPromptWithinTheWaitShowsThePickerWithANote() async {
        let (viewModel, session) = makeViewModel(FakeLocation(.notDetermined), session: freshSession().0)
        await viewModel.allowTapped()
        #expect(viewModel.step == .pickArea(couldNotAsk: true))
        #expect(!session.onboardingDone)
    }

    @Test func refusingInTheSystemPromptShowsThePicker() async {
        let location = FakeLocation(.notDetermined)
        let gate = Gate()
        let (viewModel, _) = makeViewModel(location, session: freshSession().0, sleep: { _ in await gate.wait() })
        let asking = Task { await viewModel.allowTapped() }
        while viewModel.step != .waitingForAnswer { await Task.yield() }
        viewModel.appBecameInactive()
        location.answer(.denied)
        viewModel.appBecameActive()
        await gate.open()
        await asking.value
        #expect(viewModel.step == .pickArea(couldNotAsk: false))
    }

    @Test func choosingAnotherAreaSavesIt() {
        let (session, settings) = freshSession()
        let (viewModel, _) = makeViewModel(FakeLocation(.denied), session: session)
        viewModel.notNowTapped()
        viewModel.selectArea("model-colony")
        viewModel.doneTapped()
        #expect(settings.selectedAreaID == "model-colony")
    }

    // MARK: Areas

    @Test func areasComeFromThePlacesWithKothrudFirst() async {
        let (viewModel, _) = makeViewModel(FakeLocation(.denied))
        await viewModel.loadAreas()
        #expect(viewModel.areas.first == LocationViewModel.defaultArea)
        #expect(Set(viewModel.areas.map(\.id)).count == viewModel.areas.count)
    }

    @Test func areaIDsAreLowerCaseWithDashes() {
        #expect(LocationViewModel.areaID(for: "Kothrud") == "kothrud")
        #expect(LocationViewModel.areaID(for: "Model Colony") == "model-colony")
    }

    @Test func textsResolveToRealText() {
        #expect(LocationText.why == "To show Hangouts near you and guide you while you walk.")
        #expect(LocationText.allow == "Allow location")
        #expect(LocationText.notNow == "Not now")
    }
}
