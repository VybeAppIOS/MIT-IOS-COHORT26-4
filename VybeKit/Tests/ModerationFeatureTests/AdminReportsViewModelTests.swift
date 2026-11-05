import Core
import Foundation
import Models
import Testing
@testable import ModerationFeature

@MainActor
struct AdminReportsViewModelTests {
    private func make(team: Bool = true) -> (AdminReportsViewModel, AppDependencies) {
        let deps = AppDependencies.preview(.loaded)
        let session = SessionStore(settings: AppSettings(suiteName: "vybe.test.admin.\(team)"),
                                   currentUser: SampleData.signedInUser, isTeamAccount: team)
        return (AdminReportsViewModel(admin: deps.admin, session: session, router: deps.router, now: deps.now), deps)
    }

    private func report(_ id: String, _ reason: ReportReason, hoursAgo: Double) -> Report {
        Report(id: ReportID(id), reporterID: "u1", target: .comment("c1"), reason: reason,
               createdAt: SampleData.day.addingTimeInterval(-hoursAgo * 60 * 60))
    }

    @Test func mostUrgentFirstThenOldest() {
        let ordered = ReportUrgency.ordered([
            report("spam-old", .spam, hoursAgo: 50), report("hate", .hate, hoursAgo: 1),
            report("nudity-new", .nudity, hoursAgo: 0.5), report("nudity-old", .nudity, hoursAgo: 1)
        ])
        #expect(ordered.map(\.id) == ["nudity-old", "nudity-new", "hate", "spam-old"])
    }

    @Test func deadlinesFollowTheRules() {
        let day = SampleData.day
        #expect(ReportUrgency.deadline(for: report("a", .nudity, hoursAgo: 0)) == day.addingTimeInterval(2 * 3600))
        #expect(ReportUrgency.deadline(for: report("b", .hate, hoursAgo: 0)) == day.addingTimeInterval(36 * 3600))
        #expect(ReportUrgency.deadline(for: report("c", .spam, hoursAgo: 0)) == day.addingTimeInterval(168 * 3600))
    }

    @Test func timeLeftSaysLeftOrOverdue() {
        #expect(AdminReportsViewModel.timeLeftText(80 * 60).contains("20"))
        #expect(AdminReportsViewModel.timeLeftText(-30 * 60) != AdminReportsViewModel.timeLeftText(30 * 60))
    }

    @Test func openReportsLoadInOrderWithTimeLeft() async throws {
        let (viewModel, _) = make()
        await viewModel.load()
        guard case .loaded(let rows, _) = viewModel.state else { Issue.record("not loaded"); return }
        // The sample has two open reports: impersonation (9 h ago) and harassment (4 h ago), both 36 h.
        #expect(rows.map(\.id) == ["report-sample-2", "report-sample-1"])
        #expect(rows.allSatisfy { !$0.isOverdue && !$0.timeLeftText.isEmpty })
    }

    @Test func hiddenForNonTeamAccounts() async {
        let (viewModel, _) = make(team: false)
        await viewModel.load()
        #expect(!viewModel.isAllowed && viewModel.state == .loading)
    }

    @Test func hideAsksFirstThenLeavesTheQueue() async throws {
        let (viewModel, _) = make()
        await viewModel.load()
        viewModel.hideTapped("report-sample-1")
        #expect(viewModel.isConfirmingHide)
        await viewModel.hideConfirmed()
        guard case .loaded(let rows, _) = viewModel.state else { Issue.record("not loaded"); return }
        #expect(rows.map(\.id) == ["report-sample-2"])
    }

    @Test func banOpensTheUsersPage() {
        let (viewModel, deps) = make()
        viewModel.banOwnerTapped()
        #expect(deps.router.path(for: deps.router.currentStack) == [.admin(.users)])
    }
}
