import Core
import Models
import SwiftUI

/// The only public type in ModerationFeature (ADR 002). The App's screen factory calls these; each one builds the
/// feature's View and ViewModel from `AppDependencies`. A screen task replaces only its own placeholder `case`.
public enum ModerationScreens {
    @ViewBuilder
    public static func view(for route: ModerationRoute, _ deps: AppDependencies) -> some View {
        switch route {
        case .report(let target):
            ReportView(viewModel: ReportViewModel(
                target: target, presentation: .pushed, safety: deps.safety, session: deps.session,
                router: deps.router))
        case .admin(.reports):
            AdminReportsView(viewModel: AdminReportsViewModel(
                admin: deps.admin, session: deps.session, router: deps.router, now: deps.now))
        case .admin(.placeSuggestions):
            AdminSuggestionsView(viewModel: AdminSuggestionsViewModel(
                admin: deps.admin, session: deps.session, now: deps.now))
        case .admin(.users):
            AdminUsersView(viewModel: AdminUsersViewModel(admin: deps.admin, session: deps.session))
        }
    }

    @ViewBuilder
    public static func reportSheet(_ target: ReportTarget, _ deps: AppDependencies) -> some View {
        ReportView(viewModel: ReportViewModel(
            target: target, presentation: .sheet, safety: deps.safety, session: deps.session, router: deps.router))
    }

    @ViewBuilder
    public static func blockConfirmSheet(_ user: UserID, _ deps: AppDependencies) -> some View {
        BlockConfirmView(viewModel: BlockConfirmViewModel(
            userID: user, profiles: deps.profiles, safety: deps.safety, session: deps.session, router: deps.router))
    }
}

