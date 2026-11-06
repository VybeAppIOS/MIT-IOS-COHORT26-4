import Core
import Models
import Testing
@testable import ProfileFeature

@MainActor
struct SettingsViewModelTests {
    private func make() -> (viewModel: SettingsViewModel, deps: AppDependencies) {
        let deps = AppDependencies.preview(.loaded)
        return (SettingsViewModel(session: deps.session, router: deps.router), deps)
    }

    @Test func everySettingsPageHasARowInOrder() {
        let (viewModel, _) = make()
        let routes = viewModel.sections.flatMap(\.rows).map(\.route)
        #expect(routes == [.settingsPage(.account), .settingsPage(.privacy), .settingsPage(.blocked),
                           .settingsPage(.notifications), .settingsPage(.help), .settingsPage(.placeSuggestions),
                           .settingsPage(.about)])
        #expect(viewModel.sections.flatMap(\.rows).allSatisfy { !$0.title.isEmpty && !$0.title.hasPrefix("profile.") })
    }

    /// Admin is reachable only by `-debugRoute` (decision of 5 Nov): never a row, not even for team accounts.
    @Test func thereIsNoAdminRow() {
        let (viewModel, _) = make()
        let routes = viewModel.sections.flatMap(\.rows).map(\.route)
        #expect(!routes.contains(.admin(.reports)))
    }

    @Test func aRowOpensItsPage() {
        let (viewModel, deps) = make()
        deps.router.selectedTab = .profile
        let privacy = viewModel.sections[0].rows[1]
        viewModel.rowTapped(privacy)
        #expect(deps.router.path(for: .tab(.profile)) == [.settingsPage(.privacy)])
    }

    @Test func resetAsksFirst() {
        let (viewModel, deps) = make()
        viewModel.resetTapped()
        #expect(viewModel.isConfirmingReset)
        #expect(deps.session.onboardingDone)
    }

    @Test func confirmingResetClearsOnboardingAndEveryStack() {
        let (viewModel, deps) = make()
        deps.router.selectedTab = .profile
        deps.router.open(.settings)
        viewModel.resetTapped()
        viewModel.resetConfirmed()
        #expect(!deps.session.onboardingDone)
        #expect(deps.router.paths.isEmpty)
        #expect(deps.router.selectedTab == .discover)
        #expect(!viewModel.isConfirmingReset)
    }
}
