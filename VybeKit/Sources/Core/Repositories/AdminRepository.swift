import Foundation
import Models

/// The hidden admin screens. The server enforces access; the app only hides the entry for non-team accounts.
public protocol AdminRepository: Sendable {
    func reports() async throws -> [Report]
    func setStatus(_ status: ReportStatus, for report: ReportID) async throws
    func placeSuggestions() async throws -> [PlaceSuggestion]
    /// Approves a suggestion into a (possibly edited) Place.
    func approve(_ id: PlaceSuggestionID, as place: Place) async throws
    func reject(_ id: PlaceSuggestionID, note: String) async throws
    func user(username: String) async throws -> UserProfile
    func ban(_ user: UserID) async throws
    func unban(_ user: UserID) async throws
}
