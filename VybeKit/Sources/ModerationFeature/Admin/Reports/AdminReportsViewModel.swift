import Core
import Foundation
import Models

/// One open report, ready to draw.
struct AdminReportRow: Identifiable, Equatable {
    let id: ReportID
    let reasonText: String
    /// "Comment", "Post", "User"...
    let targetText: String
    /// "1 h 20 min left" or "Overdue by 30 min".
    let timeLeftText: String
    let isOverdue: Bool
    let isUrgent: Bool
    /// Hidden for the reporter at once (nudity, self-harm, threats).
    let isAutoHidden: Bool
    let detail: String?
    let ownerID: UserID?
}

extension AdminReportRow {
    /// Stand-in row for the loading shimmer (redacted, so its words are never read).
    static let placeholder = AdminReportRow(
        id: "placeholder", reasonText: AdminReportsViewModel.reasonText(.harassment), targetText: "",
        timeLeftText: AdminReportsViewModel.timeLeftText(60 * 60), isOverdue: false, isUrgent: false,
        isAutoHidden: false, detail: nil, ownerID: nil)
}

/// AD1, the reports queue. Team accounts only (the server enforces it; this screen just will not load for anyone
/// else). Open reports, most urgent first, each with the time left to act. A report's detail offers Hide (confirmed),
/// Dismiss and "Ban the owner" (opens AD3).
@MainActor @Observable
final class AdminReportsViewModel {
    private(set) var state: LoadState<[AdminReportRow]> = .loading
    /// The report whose detail is up.
    var selected: AdminReportRow?
    /// The report waiting for "Hide?" to be confirmed.
    var pendingHide: ReportID?
    private(set) var actionFailed = false

    private let admin: any AdminRepository
    private let session: SessionStore
    private let router: Router
    private let now: @Sendable () -> Date
    private var hasLoaded = false

    /// Cheap: nothing loads here (ADR 005).
    init(admin: any AdminRepository, session: SessionStore, router: Router, now: @escaping @Sendable () -> Date) {
        self.admin = admin
        self.session = session
        self.router = router
        self.now = now
    }

    var title: String { String(localized: "admin.reports.title", bundle: #bundle) }
    var emptyMessage: String { String(localized: "admin.reports.empty", bundle: #bundle) }
    var teamOnlyMessage: String { String(localized: "admin.teamOnly", bundle: #bundle) }
    var actionError: String { String(localized: "admin.actionFailed", bundle: #bundle) }
    var isAllowed: Bool { session.isTeamAccount }

    var isConfirmingHide: Bool {
        get { pendingHide != nil }
        set { if !newValue { pendingHide = nil } }
    }

    func load() async {
        guard !hasLoaded else { return }
        await fetch()
    }

    func reload() async { await fetch() }

    private func fetch() async {
        guard isAllowed else { return }
        do {
            let open = try await admin.reports().filter { $0.status == .open }
            let rows = ReportUrgency.ordered(open).map(row)
            state = rows.isEmpty ? .empty : .loaded(rows)
            hasLoaded = true
        } catch is CancellationError {
            return
        } catch {
            if case .loaded(let rows, _) = state {
                state = .loaded(rows, isStale: true)
            } else {
                state = .failed(AppError(error))
            }
        }
    }

    private func row(_ report: Report) -> AdminReportRow {
        let urgency = ReportUrgency(report.reason)
        let left = ReportUrgency.deadline(for: report).timeIntervalSince(now())
        return AdminReportRow(
            id: report.id, reasonText: Self.reasonText(report.reason),
            targetText: Self.word("admin.target.", Self.kind(report.target)),
            timeLeftText: Self.timeLeftText(left), isOverdue: left < 0, isUrgent: urgency == .urgent,
            isAutoHidden: report.reason.hidesContentImmediately, detail: report.detail, ownerID: report.targetOwnerID)
    }

    /// "1 h 20 min left" / "Overdue by 30 min". Whole minutes, at most two units.
    static func timeLeftText(_ seconds: TimeInterval) -> String {
        let minutes = Int((abs(seconds) / 60).rounded(.down))
        let duration = Duration.seconds(minutes * 60)
            .formatted(.units(allowed: [.days, .hours, .minutes], width: .abbreviated, maximumUnitCount: 2))
        let key = seconds < 0 ? "admin.reports.overdue" : "admin.reports.left"
        let format = String(localized: String.LocalizationValue(stringLiteral: key), bundle: #bundle)
        return String(format: format, duration)
    }

    /// The Report screen's words for each reason ("moderation.report.reason.selfHarm"), keyed by the case name.
    static func reasonText(_ reason: ReportReason) -> String {
        word("moderation.report.reason.", reason == .unknown ? "other" : String(describing: reason))
    }

    private static func kind(_ target: ReportTarget) -> String {
        switch target {
        case .run: "run"
        case .comment: "comment"
        case .user: "user"
        case .message: "message"
        case .place: "place"
        case .hangout: "hangout"
        }
    }

    private static func word(_ prefix: String, _ key: String) -> String {
        String(localized: String.LocalizationValue(stringLiteral: prefix + key), bundle: #bundle)
    }

    // MARK: What the person does

    func rowTapped(_ row: AdminReportRow) { selected = row }
    func hideTapped(_ id: ReportID) { pendingHide = id }

    /// Marks the report as acted on. Hiding the content itself needs a server call that does not exist yet.
    func hideConfirmed() async {
        guard let id = pendingHide else { return }
        pendingHide = nil
        await setStatus(.actioned, for: id)
    }

    func dismissTapped(_ id: ReportID) async { await setStatus(.dismissed, for: id) }

    func banOwnerTapped() {
        selected = nil
        router.open(.admin(.users))
    }

    private func setStatus(_ status: ReportStatus, for id: ReportID) async {
        do {
            try await admin.setStatus(status, for: id)
            actionFailed = false
            selected = nil
            await fetch()
        } catch is CancellationError {
            return
        } catch {
            actionFailed = true
        }
    }
}
