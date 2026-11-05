import Core
import Models
import Testing
@testable import ModerationFeature

@MainActor
struct BlockConfirmViewModelTests {
    private let person = SampleSocialData.aarav.id

    private func make(_ mode: StubMode = .loaded) -> (viewModel: BlockConfirmViewModel, deps: AppDependencies) {
        let deps = AppDependencies.preview(mode)
        let viewModel = BlockConfirmViewModel(userID: person, profiles: deps.profiles, safety: deps.safety,
                                              session: deps.session, router: deps.router)
        return (viewModel, deps)
    }

    @Test func theTitleUsesTheirNameOnceLoaded() async {
        let (viewModel, _) = make()
        #expect(viewModel.name == nil)
        await viewModel.load()
        #expect(viewModel.name == SampleSocialData.aarav.displayName)
        #expect(viewModel.title.contains(SampleSocialData.aarav.displayName))
    }

    @Test func aMissingNameKeepsAGenericTitle() async {
        let (viewModel, _) = make(.failing)
        await viewModel.load()
        #expect(viewModel.name == nil)
        #expect(!viewModel.title.isEmpty)
    }

    @Test func blockingHidesThemEverywhereAndClosesTheSheet() async throws {
        let (viewModel, deps) = make()
        deps.router.present(.blockConfirm(person))
        await viewModel.blockTapped()
        #expect(deps.session.isBlocked(person))
        #expect(deps.router.sheet == nil)
        let blocked = try await deps.safety.blocked()
        #expect(blocked.map(\.id).contains(person))
    }

    @Test func afterBlockingTheirPostsLeaveTheFeed() async throws {
        let (viewModel, deps) = make()
        let before = try await deps.feed.feed(after: nil)
        #expect(before.items.contains { $0.runnerID == person })
        await viewModel.blockTapped()
        let after = try await deps.feed.feed(after: nil)
        #expect(!after.items.contains { $0.runnerID == person })
    }

    @Test func aFailedBlockKeepsTheSheetSoTheyCanTryAgain() async {
        let (viewModel, deps) = make(.failing)
        deps.router.present(.blockConfirm(person))
        await viewModel.blockTapped()
        #expect(viewModel.phase == .failed)
        #expect(!deps.session.isBlocked(person))
        #expect(deps.router.sheet != nil)
    }

    @Test func cancelClosesWithoutBlocking() {
        let (viewModel, deps) = make()
        deps.router.present(.blockConfirm(person))
        viewModel.cancelTapped()
        #expect(deps.router.sheet == nil)
        #expect(!deps.session.isBlocked(person))
    }
}
