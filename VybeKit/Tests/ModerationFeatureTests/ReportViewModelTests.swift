import Core
import Foundation
import Models
import Testing
@testable import ModerationFeature

@MainActor
struct ReportViewModelTests {
    private let target = ReportTarget.comment(CommentID("comment-example"))

    private func make(
        _ mode: StubMode = .loaded, presentation: ReportPresentation = .sheet
    ) -> (viewModel: ReportViewModel, deps: AppDependencies) {
        let deps = AppDependencies.preview(mode)
        let viewModel = ReportViewModel(target: target, presentation: presentation, safety: deps.safety,
                                        router: deps.router)
        return (viewModel, deps)
    }

    @Test func everyReasonIsListedOnceInTheTaskOrder() {
        let reasons = make().viewModel.reasons.map(\.reason)
        let expected = ReportReason.allCases.filter { $0 != .unknown }
        #expect(reasons == expected)
        #expect(reasons.count == 15)
    }

    @Test(arguments: ReportReason.allCases.filter { $0 != .unknown && $0 != .other })
    func eachReasonIsSentAsItself(reason: ReportReason) async throws {
        let (viewModel, deps) = make()
        viewModel.select(reason)
        await viewModel.sendTapped()
        #expect(viewModel.phase == .sent(hidden: reason.hidesContentImmediately))
        let filed = try await deps.admin.reports()
        #expect(filed.map(\.reason).contains(reason))
    }

    @Test func nudityAndSelfHarmAndThreatsHideTheContentAtOnce() async {
        for reason in [ReportReason.nudity, .selfHarm, .violence] {
            let (viewModel, _) = make()
            viewModel.select(reason)
            await viewModel.sendTapped()
            #expect(viewModel.phase == .sent(hidden: true))
        }
        let (spam, _) = make()
        spam.select(.spam)
        await spam.sendTapped()
        #expect(spam.phase == .sent(hidden: false))
    }

    @Test func selfHarmShowsBothHelpNumbers() {
        let (viewModel, _) = make()
        #expect(!viewModel.showsHelp)
        viewModel.select(.selfHarm)
        #expect(viewModel.showsHelp)
        #expect(viewModel.helpLines.map(\.number) == ["14416", "112"])
        #expect(viewModel.helpLines.allSatisfy { $0.url != nil })
    }

    @Test func sendNeedsAReason() {
        let (viewModel, _) = make()
        #expect(!viewModel.canSend)
        viewModel.select(.spam)
        #expect(viewModel.canSend)
    }

    @Test func somethingElseNeedsWordsAndAtMost300Characters() {
        let (viewModel, _) = make()
        viewModel.select(.other)
        #expect(viewModel.showsDetail)
        #expect(!viewModel.canSend)
        viewModel.detail = "   "
        #expect(!viewModel.canSend)
        viewModel.detail = "A stranger's number is on this post."
        #expect(viewModel.canSend)
        viewModel.detail = String(repeating: "a", count: 300)
        #expect(viewModel.canSend)
        viewModel.detail = String(repeating: "a", count: 301)
        #expect(!viewModel.canSend)
        #expect(viewModel.isDetailTooLong)
    }

    @Test func aFailedSendKeepsTheFormSoTheyCanTryAgain() async {
        let (viewModel, _) = make(.failing)
        viewModel.select(.scam)
        await viewModel.sendTapped()
        #expect(viewModel.phase == .failed)
        #expect(viewModel.selected == .scam)
        #expect(viewModel.canSend)
    }

    @Test func theSheetClosesTheSheet() {
        let (viewModel, deps) = make(presentation: .sheet)
        deps.router.present(.report(target))
        #expect(viewModel.showsCancel)
        viewModel.cancelTapped()
        #expect(deps.router.sheet == nil)
    }

    @Test func aPushedReportGoesBackAndHasNoCancel() {
        let (viewModel, deps) = make(presentation: .pushed)
        deps.router.open(.report(target))
        #expect(!viewModel.showsCancel)
        viewModel.doneTapped()
        #expect(deps.router.path(for: deps.router.currentStack).isEmpty)
    }
}
