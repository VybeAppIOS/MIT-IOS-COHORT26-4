import Foundation

/// Why something is reported. The list is in `docs/tasks/50-...` (SC-R1) and `docs/RISKS.md`.
/// String-backed with an `unknown` fallback (ADR 004): a reason added later never crashes an older app.
public enum ReportReason: String, Codable, Hashable, Sendable, CaseIterable {
    case spam
    case harassment
    case hate
    case nudity
    case violence
    case selfHarm = "self-harm"
    case illegalGoods = "illegal-goods"
    case scam
    case impersonation
    case copyright
    case photoWithoutConsent = "photo-without-consent"
    case privateAddress = "private-address"
    case unsafePlace = "unsafe-place"
    case possiblyUnderage = "possibly-underage"
    case other
    /// Any reason this app version does not know.
    case unknown

    /// Nudity, self-harm and threats are hidden for the reporter straight away (`docs/PRODUCT.md` 4, safety defaults).
    /// Never weaken this without a human.
    public var hidesContentImmediately: Bool {
        switch self {
        case .nudity, .selfHarm, .violence: true
        default: false
        }
    }

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ReportReason(rawValue: raw) ?? .unknown
    }
}

public enum ReportStatus: String, Codable, Hashable, Sendable {
    case open
    case actioned
    case dismissed
}

/// A report. Anonymous: the reported person never sees who filed it. Only the team reads reports.
public struct Report: Codable, Hashable, Sendable, Identifiable {
    public let id: ReportID
    public var reporterID: UserID
    public var target: ReportTarget
    /// Who owns the reported thing, so the team can act on them.
    public var targetOwnerID: UserID?
    public var reason: ReportReason
    /// Free text, at most 300 characters (checked by the Report screen).
    public var detail: String?
    public var status: ReportStatus
    public var createdAt: Date

    public init(
        id: ReportID, reporterID: UserID, target: ReportTarget, targetOwnerID: UserID? = nil, reason: ReportReason,
        detail: String? = nil, status: ReportStatus = .open, createdAt: Date
    ) {
        self.id = id
        self.reporterID = reporterID
        self.target = target
        self.targetOwnerID = targetOwnerID
        self.reason = reason
        self.detail = detail
        self.status = status
        self.createdAt = createdAt
    }
}
