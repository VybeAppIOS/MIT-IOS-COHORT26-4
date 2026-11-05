import Core
import Foundation
import Models
import Testing
@testable import ModerationFeature

@MainActor
struct AdminUsersViewModelTests {
    private func make(_ mode: StubMode = .loaded, team: Bool = true) -> AdminUsersViewModel {
        let deps = AppDependencies.preview(mode)
        let session = SessionStore(settings: AppSettings(suiteName: "vybe.test.users.\(team)"),
                                   currentUser: SampleData.signedInUser, isTeamAccount: team)
        return AdminUsersViewModel(admin: deps.admin, session: session)
    }

    private func card(_ viewModel: AdminUsersViewModel) -> AdminUserCard? {
        if case .loaded(let card, _) = viewModel.state { return card }
        return nil
    }

    @Test func startsEmptyUntilASearch() {
        #expect(make().state == .empty)
    }

    @Test func findsAPersonWithTheReportsAgainstThem() async throws {
        let viewModel = make()
        viewModel.query = " @\(SampleSocialData.kabir.username.uppercased()) "
        await viewModel.searchSubmitted()
        let found = try #require(card(viewModel))
        #expect(found.id == SampleSocialData.kabir.id)
        #expect(found.reportLines.count == 2)   // the sample impersonation (open) and nudity (actioned) reports
    }

    @Test func anUnknownUsernameIsNotFound() async {
        let viewModel = make()
        viewModel.query = "nobody.here"
        await viewModel.searchSubmitted()
        #expect(viewModel.state == .failed(.notFound))
    }

    @Test func banAndUnbanAskFirst() async throws {
        let viewModel = make()
        viewModel.query = SampleSocialData.kabir.username
        await viewModel.searchSubmitted()
        viewModel.banTapped()
        #expect(viewModel.isConfirming && viewModel.resultText == nil)
        await viewModel.actionConfirmed()
        #expect(viewModel.resultText != nil && !viewModel.actionFailed)
        viewModel.unbanTapped()
        #expect(viewModel.pendingAction == .unban)
        await viewModel.actionConfirmed()
        #expect(!viewModel.isConfirming && !viewModel.actionFailed)
    }

    @Test func aFailedSearchShowsTheError() async {
        let viewModel = make(.failing)
        viewModel.query = "sample"
        await viewModel.searchSubmitted()
        if case .failed = viewModel.state {} else { Issue.record("expected failed") }
    }

    @Test func hiddenForNonTeamAccounts() async {
        let viewModel = make(team: false)
        viewModel.query = SampleSocialData.kabir.username
        await viewModel.searchSubmitted()
        #expect(!viewModel.isAllowed && viewModel.state == .empty)
    }
}
