import Foundation
import Models

/// How fast the team must act on a report. The hours follow India's IT Rules as written in `docs/RISKS.md` (row 5):
/// 2 h for nudity and morphed images (and child safety), 36 h for unlawful content, 7 days for everything else.
/// Which reason falls into which group is a proposal waiting for a human (see the WO-3 report, "Decisions I need").
enum ReportUrgency: Int, Comparable {
    /// 2 hours, shown first.
    case urgent = 0
    /// 36 hours.
    case unlawful = 1
    /// 7 days.
    case general = 2

    init(_ reason: ReportReason) {
        switch reason {
        case .nudity, .photoWithoutConsent, .possiblyUnderage: self = .urgent
        case .selfHarm, .violence, .hate, .harassment, .illegalGoods, .privateAddress, .impersonation, .copyright:
            self = .unlawful
        case .spam, .scam, .unsafePlace, .other, .unknown: self = .general
        }
    }

    var hours: Double {
        switch self {
        case .urgent: 2
        case .unlawful: 36
        case .general: 7 * 24
        }
    }

    static func < (lhs: ReportUrgency, rhs: ReportUrgency) -> Bool { lhs.rawValue < rhs.rawValue }

    /// When the team must have acted.
    static func deadline(for report: Report) -> Date {
        report.createdAt.addingTimeInterval(ReportUrgency(report.reason).hours * 60 * 60)
    }

    /// Most urgent group first; inside a group, the oldest report first (it has the least time left).
    static func ordered(_ reports: [Report]) -> [Report] {
        reports.sorted {
            let left = ReportUrgency($0.reason)
            let right = ReportUrgency($1.reason)
            return left == right ? $0.createdAt < $1.createdAt : left < right
        }
    }
}
