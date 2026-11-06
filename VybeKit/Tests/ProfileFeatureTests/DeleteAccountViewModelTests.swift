import Core
import Models
import Testing
@testable import ProfileFeature

@MainActor
struct DeleteAccountViewModelTests {
    private func make(_ mode: StubMode = .loaded) -> (viewModel: DeleteAccountViewModel, deps: AppDependencies) {
        let deps = AppDependencies.preview(mode)
        let viewModel = DeleteAccountViewModel(
            auth: deps.auth, session: deps.session, libraryStore: deps.libraryStore, liveStore: deps.liveStore,
            network: deps.network, router: deps.router)
        return (viewModel, deps)
    }

    @Test(arguments: [("sample.me", true), (" @Sample.Me ", true), ("sample.you", false), ("", false)])
    func theConfirmTextMustMatchTheUsername(typed: String, matches: Bool) {
        let (viewModel, _) = make()
        viewModel.typedUsername = typed
        #expect(viewModel.matches == matches)
        #expect(viewModel.canDelete == matches)
    }

    @Test func aWrongUsernameShowsAnErrorButAnEmptyFieldDoesNot() {
        let (viewModel, _) = make()
        #expect(viewModel.fieldError == nil)
        viewModel.typedUsername = "someone"
        #expect(viewModel.fieldError != nil)
    }

    @Test func deletingClearsTheLibraryTheLiveRunTheSessionAndTheRouter() async throws {
        let (viewModel, deps) = make()
        await deps.libraryStore.load()
        #expect(!deps.libraryStore.library.saves.isEmpty)   // the loaded stub starts with one saved Hangout
        _ = try await deps.liveStore.startOrResume(hangoutID: SampleData.evening.id)
        #expect(deps.liveStore.isLive)
        deps.router.selectedTab = .profile
        deps.router.open(.deleteAccount)

        viewModel.typedUsername = SampleData.signedInUser.username
        await viewModel.deleteTapped()

        #expect(!deps.liveStore.isLive)
        let saved = try await deps.library.load()
        #expect(saved.saves.isEmpty && saved.drafts.isEmpty && saved.runs.isEmpty && saved.runTimes.isEmpty)
        #expect(deps.session.currentUser == nil && !deps.session.onboardingDone)
        #expect(deps.router.paths.isEmpty)
    }

    @Test func aFailedDeleteKeepsEverythingOnThePhone() async {
        let (viewModel, deps) = make(.failing)
        viewModel.typedUsername = SampleData.signedInUser.username
        await viewModel.deleteTapped()
        #expect(viewModel.phase == .failed)
        #expect(deps.session.currentUser != nil)
    }

    @Test func nothingIsDeletedOffline() async {
        let (viewModel, deps) = make()
        deps.network.forceOffline(true)
        viewModel.typedUsername = SampleData.signedInUser.username
        #expect(!viewModel.canDelete)
        await viewModel.deleteTapped()
        #expect(deps.session.currentUser != nil)
    }
}
