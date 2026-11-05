import Core
import Models
import Testing
@testable import ProfileFeature

@MainActor
struct AccountSettingsViewModelTests {
    private func make(_ mode: StubMode = .loaded) -> (viewModel: AccountSettingsViewModel, deps: AppDependencies) {
        let deps = AppDependencies.preview(mode)
        let viewModel = AccountSettingsViewModel(auth: deps.auth, session: deps.session, network: deps.network,
                                                 router: deps.router)
        return (viewModel, deps)
    }

    @Test func showsWhoIsSignedIn() {
        let (viewModel, _) = make()
        #expect(viewModel.name == SampleData.signedInUser.displayName)
        #expect(viewModel.username == "@\(SampleData.signedInUser.username)")
    }

    @Test func signOutAsksFirst() {
        let (viewModel, deps) = make()
        viewModel.signOutTapped()
        #expect(viewModel.isConfirmingSignOut)
        #expect(deps.session.currentUser != nil)
    }

    @Test func signingOutClearsTheSessionAndTheRouter() async {
        let (viewModel, deps) = make()
        deps.router.selectedTab = .profile
        deps.router.open(.settings)
        viewModel.signOutTapped()
        await viewModel.signOutConfirmed()
        #expect(deps.session.currentUser == nil)
        #expect(!deps.session.onboardingDone)
        #expect(deps.router.paths.isEmpty)
        #expect(viewModel.phase == .idle)
    }

    @Test func aFailedSignOutKeepsThePersonSignedIn() async {
        let (viewModel, deps) = make(.failing)
        await viewModel.signOutConfirmed()
        #expect(viewModel.phase == .failed)
        #expect(deps.session.currentUser != nil)
    }

    @Test func signOutWaitsForAConnection() async {
        let (viewModel, deps) = make()
        deps.network.forceOffline(true)
        #expect(!viewModel.canSignOut)
        await viewModel.signOutConfirmed()
        #expect(deps.session.currentUser != nil)
    }

    @Test func deleteAccountOpensItsPage() {
        let (viewModel, deps) = make()
        deps.router.selectedTab = .profile
        viewModel.deleteAccountTapped()
        #expect(deps.router.path(for: .tab(.profile)) == [.deleteAccount])
    }
}
