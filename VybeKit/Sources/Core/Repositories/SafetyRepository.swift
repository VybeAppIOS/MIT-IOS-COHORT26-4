import Foundation
import Models

public protocol SafetyRepository: Sendable {
    /// Files an anonymous report; the reported person never sees who reported.
    func report(_ target: ReportTarget, reason: ReportReason, detail: String?) async throws -> Report
    func block(_ user: UserID) async throws
    func unblock(_ user: UserID) async throws
    func blocked() async throws -> [UserProfile]
}
