import Core
import Models
import Testing
@testable import ProfileFeature

@MainActor
struct ProfileViewModelTests {
    private func make(_ mode: StubMode = .loaded) -> (viewModel: ProfileViewModel, deps: AppDependencies) {
        let deps = AppDependencies.preview(mode)
        let viewModel = ProfileViewModel(profiles: deps.profiles, auth: deps.auth, feed: deps.feed,
                                         photos: deps.photos, session: deps.session, libraryStore: deps.libraryStore,
                                         router: deps.router)
        return (viewModel, deps)
    }

    @Test func loadsTheHeaderFromMyProfile() async {
        let (viewModel, _) = make()
        await viewModel.load()
        guard case .loaded(let content, _) = viewModel.state else {
            Issue.record("expected loaded, got \(viewModel.state)")
            return
        }
        #expect(content.header.name == SampleData.signedInUser.displayName)
        #expect(content.header.username == "@\(SampleData.signedInUser.username)")
        #expect(content.header.friendCount == SampleData.signedInUser.friendCount)
    }

    @Test func libraryCountsComeFromTheLibrary() async {
        let (viewModel, deps) = make()
        await viewModel.load()
        let counts = Dictionary(uniqueKeysWithValues: viewModel.libraryRows.map { ($0.id, $0.count) })
        #expect(counts["saved"] == deps.libraryStore.library.saves.count)
        #expect(counts["drafts"] == 0 && counts["ready"] == 0)
        await deps.libraryStore.toggleSave(SampleData.morning.id)
        #expect(viewModel.libraryRows[0].count == deps.libraryStore.library.saves.count)
    }

    @Test func statsCountMyRunsAndTheirSpotsButNeverTimes() async throws {
        let (viewModel, deps) = make()
        _ = try await deps.liveStore.startOrResume(hangoutID: SampleData.evening.id)
        deps.liveStore.markVisited(spotID: "s1")
        deps.liveStore.markVisited(spotID: "s2")
        deps.liveStore.end()
        await viewModel.load()
        guard case .loaded(let content, _) = viewModel.state else {
            Issue.record("expected loaded")
            return
        }
        #expect(content.header.hangoutsDone == 1 && content.header.spotsVisited == 2)
    }

    @Test func rowsGearAndPostsNavigate() {
        let (viewModel, deps) = make()
        deps.router.selectedTab = .profile
        viewModel.libraryRowTapped(viewModel.libraryRows[1])
        viewModel.settingsTapped()
        viewModel.postTapped("run-1")
        #expect(deps.router.path(for: .tab(.profile)) == [.drafts, .settings, .post("run-1")])
    }

    @Test func editOpensTheSheetWithMyProfile() async {
        let (viewModel, _) = make()
        await viewModel.load()
        viewModel.editTapped()
        #expect(viewModel.editing?.id == SampleData.signedInUser.id)
        #expect(viewModel.makeEditViewModel(SampleData.signedInUser).name == SampleData.signedInUser.displayName)
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let (viewModel, _) = make(.failing)
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }
}
