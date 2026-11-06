import Core
import Foundation
import Models

/// The person found, ready to draw.
struct AdminUserCard: Equatable {
    let id: UserID
    let name: String
    /// "@sample.kabir"
    let username: String
    /// "2 open reports" / "No reports"
    let reportsText: String
    /// One line per report against them: "Impersonation · open".
    let reportLines: [String]
}

/// AD3, Users. Team accounts only. Look up a person by username (this admin tool may search people), see the
/// reports against them, and ban or unban (each asks first). Nothing loads until a search: the page starts empty.
@MainActor @Observable
final class AdminUsersViewModel {
    enum BanAction: Equatable {
        case ban
        case unban
    }

    var query = ""
    private(set) var state: LoadState<AdminUserCard> = .empty
    /// The ban or unban waiting to be confirmed.
    var pendingAction: BanAction?
    /// What the last ban or unban did, said in words ("Banned." / "Unbanned.").
    private(set) var resultText: String?
    private(set) var actionFailed = false

    private let admin: any AdminRepository
    private let session: SessionStore

    /// Cheap: nothing loads here (ADR 005).
    init(admin: any AdminRepository, session: SessionStore) {
        self.admin = admin
        self.session = session
    }

    var title: String { String(localized: "admin.users.title", bundle: #bundle) }
    var searchPrompt: String { String(localized: "admin.users.search", bundle: #bundle) }
    var emptyMessage: String { String(localized: "admin.users.empty", bundle: #bundle) }
    var teamOnlyMessage: String { String(localized: "admin.teamOnly", bundle: #bundle) }
    var actionError: String { String(localized: "admin.actionFailed", bundle: #bundle) }
    var banTitle: String { String(localized: "admin.users.ban", bundle: #bundle) }
    var unbanTitle: String { String(localized: "admin.users.unban", bundle: #bundle) }
    var isAllowed: Bool { session.isTeamAccount }

    var confirmTitle: String {
        pendingAction == .unban
            ? String(localized: "admin.users.unban.confirm", bundle: #bundle)
            : String(localized: "admin.users.ban.confirm", bundle: #bundle)
    }

    var isConfirming: Bool {
        get { pendingAction != nil }
        set { if !newValue { pendingAction = nil } }
    }

    /// "@Kabir " and "kabir" find the same person.
    private var cleanQuery: String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.hasPrefix("@") ? String(trimmed.dropFirst()) : trimmed
    }

    // MARK: What the person does

    func searchSubmitted() async {
        let username = cleanQuery
        guard isAllowed, !username.isEmpty else { return }
        state = .loading
        resultText = nil
        do {
            let user = try await admin.user(username: username)
            let against = try await admin.reports().filter { $0.targetOwnerID == user.id }
            state = .loaded(card(user, reports: against))
        } catch is CancellationError {
            return
        } catch AppError.notFound {
            state = .failed(.notFound)
        } catch {
            state = .failed(AppError(error))
        }
    }

    private func card(_ user: UserProfile, reports: [Report]) -> AdminUserCard {
        let open = reports.filter { $0.status == .open }.count
        let summary = reports.isEmpty
            ? String(localized: "admin.users.noReports", bundle: #bundle)
            : String(format: String(localized: "admin.users.openReports", bundle: #bundle), open, reports.count)
        let lines = reports.sorted { $0.createdAt > $1.createdAt }.map {
            String(format: String(localized: "admin.users.reportLine", bundle: #bundle),
                   AdminReportsViewModel.reasonText($0.reason), Self.statusText($0.status))
        }
        return AdminUserCard(id: user.id, name: user.displayName, username: "@\(user.username)",
                             reportsText: summary, reportLines: lines)
    }

    private static func statusText(_ status: ReportStatus) -> String {
        String(localized: String.LocalizationValue(stringLiteral: "admin.status." + status.rawValue), bundle: #bundle)
    }

    func banTapped() { pendingAction = .ban }
    func unbanTapped() { pendingAction = .unban }

    func actionConfirmed() async {
        guard let action = pendingAction, case .loaded(let card, _) = state else { return }
        pendingAction = nil
        do {
            switch action {
            case .ban: try await admin.ban(card.id)
            case .unban: try await admin.unban(card.id)
            }
            actionFailed = false
            resultText = action == .ban
                ? String(localized: "admin.users.banned", bundle: #bundle)
                : String(localized: "admin.users.unbanned", bundle: #bundle)
        } catch is CancellationError {
            return
        } catch {
            actionFailed = true
        }
    }
}
