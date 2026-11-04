import Foundation
import Models

/// Sheets that more than one feature can ask for. Shown by exactly one host at a time (ADR 003).
/// A sheet that only one feature shows stays a flag in that screen's ViewModel instead.
public enum Sheet: Hashable, Codable, Sendable, Identifiable {
    /// HD2: opened from Search, Hangout detail and the live screen.
    case spot(PlaceID)
    /// R1.
    case report(ReportTarget)
    /// CH5.
    case share(ShareItem)
    /// E3: opened from Search (empty) and the editor.
    case suggestPlace
    /// PO2: opened from the post detail.
    case editPost(RunID)
    /// CH7.
    case groupInvitation(ConversationID)

    public var id: String {
        switch self {
        case .spot(let id): "spot-\(id.rawValue)"
        case .report: "report"
        case .share: "share"
        case .suggestPlace: "suggestPlace"
        case .editPost(let id): "editPost-\(id.rawValue)"
        case .groupInvitation(let id): "invite-\(id.rawValue)"
        }
    }
}
