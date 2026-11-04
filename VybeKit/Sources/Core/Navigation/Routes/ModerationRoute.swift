import Foundation
import Models

/// R1 pushed inside a sheet, and the hidden admin pages AD1 to AD3.
public enum ModerationRoute: Hashable, Codable, Sendable {
    case report(ReportTarget)
    case admin(AdminPage)
}

public extension Route {
    static func report(_ target: ReportTarget) -> Route { .moderation(.report(target)) }
    static func admin(_ page: AdminPage) -> Route { .moderation(.admin(page)) }
}
