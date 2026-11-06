import Core
import Foundation
import Models
import Testing
@testable import ModerationFeature

@MainActor
struct AdminSuggestionsViewModelTests {
    private func make(_ mode: StubMode = .loaded, team: Bool = true) -> (AdminSuggestionsViewModel, AppDependencies) {
        let deps = AppDependencies.preview(mode)
        let session = SessionStore(settings: AppSettings(suiteName: "vybe.test.suggestions.\(team)"),
                                   currentUser: SampleData.signedInUser, isTeamAccount: team)
        return (AdminSuggestionsViewModel(admin: deps.admin, session: session, now: deps.now), deps)
    }

    private func rows(_ viewModel: AdminSuggestionsViewModel) -> [AdminSuggestionRow] {
        if case .loaded(let rows, _) = viewModel.state { return rows }
        return []
    }

    @Test func pendingSuggestionsLoad() async {
        let (viewModel, _) = make()
        await viewModel.load()
        #expect(rows(viewModel).map(\.id) == ["suggestion-sample-2", "suggestion-sample-1"])
    }

    @Test func approvingNeedsTheDetailsThenTurnsItIntoAPlace() async throws {
        let (viewModel, deps) = make()
        await viewModel.load()
        let first = try #require(rows(viewModel).first)
        viewModel.rowTapped(first)
        #expect(viewModel.isReviewing && !viewModel.canApprove)
        viewModel.draft.area = "Kothrud"
        viewModel.draft.address = "EXAMPLE address"
        viewModel.draft.costUpper = 200
        #expect(viewModel.canApprove)
        await viewModel.approveTapped()
        #expect(!viewModel.isReviewing && !rows(viewModel).contains { $0.id == first.id })
        let saved = try await deps.admin.placeSuggestions().first { $0.id == first.id }
        #expect(saved?.status == .approved && saved?.approvedPlaceID == PlaceID("place-\(first.id.rawValue)"))
    }

    @Test func rejectingNeedsANote() async throws {
        let (viewModel, deps) = make()
        await viewModel.load()
        let first = try #require(rows(viewModel).first)
        viewModel.rowTapped(first)
        #expect(!viewModel.canReject)
        viewModel.draft.rejectNote = "Closed for good"
        await viewModel.rejectTapped()
        let saved = try await deps.admin.placeSuggestions().first { $0.id == first.id }
        #expect(saved?.status == .rejected && saved?.reviewNote == "Closed for good")
    }

    @Test func residentialIsOneTap() async throws {
        let (viewModel, deps) = make()
        await viewModel.load()
        let first = try #require(rows(viewModel).first)
        viewModel.rowTapped(first)
        await viewModel.rejectResidentialTapped()
        let saved = try await deps.admin.placeSuggestions().first { $0.id == first.id }
        #expect(saved?.status == .rejected && saved?.reviewNote?.isEmpty == false)
    }

    @Test func emptyAndFailedStates() async {
        let (empty, _) = make(.empty)
        await empty.load()
        #expect(empty.state == .empty)
        let (failing, _) = make(.failing)
        await failing.load()
        if case .failed = failing.state {} else { Issue.record("expected failed") }
    }

    @Test func hiddenForNonTeamAccounts() async {
        let (viewModel, _) = make(team: false)
        await viewModel.load()
        #expect(!viewModel.isAllowed && viewModel.state == .loading)
    }
}
