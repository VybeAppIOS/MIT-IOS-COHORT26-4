import Core
import Foundation
import Models

/// One line in the reason list, ready to draw.
struct ReportReasonRow: Identifiable, Equatable {
    let reason: ReportReason
    let title: String
    let symbol: String
    /// Drawn in the warning colour: content that can hurt someone right now.
    let isSevere: Bool

    var id: ReportReason { reason }
}

/// A phone number a person can call from the self-harm card.
struct HelpLine: Identifiable, Equatable {
    let name: String
    let number: String

    var id: String { number }
    var url: URL? { URL(string: "tel:\(number)") }
}

/// How the screen was reached: as a sheet (closes the sheet) or pushed inside another sheet (goes back).
enum ReportPresentation: Equatable {
    case sheet
    case pushed
}

/// R1, Report. A form, not a loaded list: choose a reason, add words for "something else", send, then see the thanks.
/// Anonymous: nothing here names the person who reports.
@MainActor @Observable
final class ReportViewModel {
    enum Phase: Equatable {
        case choosing
        case sending
        /// The last send did not go through. The form stays as it was so the person can try again.
        case failed
        /// `hidden`: the reason is nudity, self-harm or threats, so the content is already hidden for this person.
        case sent(hidden: Bool)
    }

    static let detailLimit = 300

    private(set) var phase: Phase = .choosing
    private(set) var selected: ReportReason?
    var detail = ""

    private let target: ReportTarget
    private let presentation: ReportPresentation
    private let safety: any SafetyRepository
    private let session: SessionStore
    private let router: Router
    /// Who owns the reported thing, once the report is filed: the person "Also block" would block.
    private(set) var ownerToBlock: UserID?

    /// Cheap: nothing loads here (ADR 005).
    init(
        target: ReportTarget, presentation: ReportPresentation, safety: any SafetyRepository, session: SessionStore,
        router: Router
    ) {
        self.target = target
        self.presentation = presentation
        self.safety = safety
        self.session = session
        self.router = router
    }

    // MARK: What the screen shows

    var title: String { String(localized: "moderation.report.title", bundle: #bundle) }

    var headline: String {
        switch target {
        case .run: String(localized: "moderation.report.headline.run", bundle: #bundle)
        case .comment: String(localized: "moderation.report.headline.comment", bundle: #bundle)
        case .user: String(localized: "moderation.report.headline.user", bundle: #bundle)
        case .message: String(localized: "moderation.report.headline.message", bundle: #bundle)
        case .place: String(localized: "moderation.report.headline.place", bundle: #bundle)
        case .hangout: String(localized: "moderation.report.headline.hangout", bundle: #bundle)
        }
    }

    var subtitle: String { String(localized: "moderation.report.subtitle", bundle: #bundle) }
    var detailPlaceholder: String { String(localized: "moderation.report.detail.placeholder", bundle: #bundle) }
    var sendTitle: String { String(localized: "moderation.report.send", bundle: #bundle) }
    var errorMessage: String { String(localized: "moderation.report.error", bundle: #bundle) }
    var thanksTitle: String { String(localized: "moderation.report.sent.title", bundle: #bundle) }
    var thanksBody: String { String(localized: "moderation.report.sent.body", bundle: #bundle) }
    var hiddenNote: String { String(localized: "moderation.report.sent.hidden", bundle: #bundle) }
    var doneTitle: String { String(localized: "moderation.report.done", bundle: #bundle) }
    var blockTitle: String { String(localized: "moderation.report.block", bundle: #bundle) }
    /// "Also block?" is offered only when we know whose it is, and it is not you and not already blocked.
    var offersBlock: Bool { isSent && ownerToBlock != nil }
    var helpTitle: String { String(localized: "moderation.report.help.title", bundle: #bundle) }
    var helpBody: String { String(localized: "moderation.report.help.body", bundle: #bundle) }

    /// Every reason in the order of the task, without the "unknown" a newer app might receive.
    let reasons: [ReportReasonRow] = ReportReasonInfo.all.map {
        ReportReasonRow(reason: $0.reason, title: String(localized: $0.title), symbol: $0.symbol, isSevere: $0.isSevere)
    }

    /// Tele-MANAS and 112, shown when the reason is self-harm (`docs/RISKS.md`).
    let helpLines: [HelpLine] = [
        HelpLine(name: String(localized: "moderation.report.help.telemanas", bundle: #bundle), number: "14416"),
        HelpLine(name: String(localized: "moderation.report.help.emergency", bundle: #bundle), number: "112")
    ]

    var showsHelp: Bool { selected == .selfHarm }
    var showsDetail: Bool { selected == .other }
    var showsCancel: Bool { presentation == .sheet }
    var isSending: Bool { phase == .sending }
    var hasFailed: Bool { phase == .failed }

    var isSent: Bool {
        if case .sent = phase { return true }
        return false
    }

    var detailCountText: String {
        String(format: String(localized: "moderation.report.detail.count", bundle: #bundle),
               detail.count, Self.detailLimit)
    }

    var isDetailTooLong: Bool { detail.count > Self.detailLimit }

    /// Sending needs a reason; "something else" also needs a few words, and never more than 300 characters.
    var canSend: Bool {
        guard let selected, phase != .sending else { return false }
        if selected == .other {
            return !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isDetailTooLong
        }
        return true
    }

    // MARK: What the person does

    func select(_ reason: ReportReason) {
        guard phase != .sending else { return }
        selected = reason
        if phase == .failed { phase = .choosing }
    }

    func sendTapped() async {
        guard let reason = selected, canSend else { return }
        phase = .sending
        let words = reason == .other ? detail.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        do {
            let filed = try await safety.report(target, reason: reason, detail: words)
            if let owner = filed.targetOwnerID, owner != session.currentUser?.id, !session.isBlocked(owner) {
                ownerToBlock = owner
            }
            phase = .sent(hidden: reason.hidesContentImmediately)
        } catch is CancellationError {
            phase = .choosing   // leaving the screen is not an error (ADR 005)
        } catch {
            phase = .failed
        }
    }

    /// Swaps this sheet for the Block confirmation (R2).
    func blockTapped() {
        guard let owner = ownerToBlock else { return }
        router.present(.blockConfirm(owner))
    }

    func cancelTapped() { close() }
    func doneTapped() { close() }

    private func close() {
        switch presentation {
        case .sheet: router.dismissSheet()
        case .pushed: router.pop()
        }
    }
}

/// The fixed table behind the reason list: words, an SF Symbol and how serious it is, in display order.
enum ReportReasonInfo {
    struct Entry {
        let reason: ReportReason
        let title: LocalizedStringResource
        let symbol: String
        let isSevere: Bool
    }

    /// A reason's words, looked up in this feature's own catalog.
    private static func text(_ key: String.LocalizationValue) -> LocalizedStringResource {
        LocalizedStringResource(key, bundle: #bundle)
    }

    static let all: [Entry] = [
        Entry(reason: .spam, title: text("moderation.report.reason.spam"), symbol: "tray.full", isSevere: false),
        Entry(reason: .harassment, title: text("moderation.report.reason.harassment"), symbol: "person.fill.xmark",
              isSevere: false),
        Entry(reason: .hate, title: text("moderation.report.reason.hate"), symbol: "hand.raised", isSevere: true),
        Entry(reason: .nudity, title: text("moderation.report.reason.nudity"), symbol: "eye.slash", isSevere: true),
        Entry(reason: .violence, title: text("moderation.report.reason.violence"), symbol: "exclamationmark.triangle",
              isSevere: true),
        Entry(reason: .selfHarm, title: text("moderation.report.reason.selfHarm"), symbol: "heart", isSevere: true),
        Entry(reason: .illegalGoods, title: text("moderation.report.reason.illegalGoods"), symbol: "pills",
              isSevere: false),
        Entry(reason: .scam, title: text("moderation.report.reason.scam"), symbol: "creditcard", isSevere: false),
        Entry(reason: .impersonation, title: text("moderation.report.reason.impersonation"), symbol: "person.2",
              isSevere: false),
        Entry(reason: .copyright, title: text("moderation.report.reason.copyright"), symbol: "c.circle",
              isSevere: false),
        Entry(reason: .photoWithoutConsent, title: text("moderation.report.reason.photoWithoutConsent"),
              symbol: "camera", isSevere: true),
        Entry(reason: .privateAddress, title: text("moderation.report.reason.privateAddress"), symbol: "house",
              isSevere: true),
        Entry(reason: .unsafePlace, title: text("moderation.report.reason.unsafePlace"), symbol: "mappin.slash",
              isSevere: false),
        Entry(reason: .possiblyUnderage, title: text("moderation.report.reason.possiblyUnderage"),
              symbol: "person.crop.circle.badge.questionmark", isSevere: true),
        Entry(reason: .other, title: text("moderation.report.reason.other"), symbol: "ellipsis.circle", isSevere: false)
    ]
}

#if DEBUG
extension ReportViewModel {
    /// Puts the screen in a given state for previews and screenshots, so each state can be seen without tapping.
    func showForPreview(
        selected: ReportReason?, phase: Phase = .choosing, detail: String = "", ownerToBlock: UserID? = nil
    ) {
        self.ownerToBlock = ownerToBlock
        self.selected = selected
        self.phase = phase
        self.detail = detail
    }
}
#endif
