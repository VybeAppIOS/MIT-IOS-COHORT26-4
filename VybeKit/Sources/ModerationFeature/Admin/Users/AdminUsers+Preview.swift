#if DEBUG
import Core
import Foundation
import Models
import SwiftUI

extension AdminUsersViewModel {
    /// The real ViewModel on the stubs, signed in as a team account unless `team` is false.
    static func preview(_ mode: StubMode = .loaded, team: Bool = true, query: String = "") -> AdminUsersViewModel {
        let deps = AppDependencies.preview(mode)
        let session = SessionStore(settings: AppSettings(suiteName: "vybe.preview.admin"),
                                   currentUser: SampleData.signedInUser, isTeamAccount: team)
        let viewModel = AdminUsersViewModel(admin: deps.admin, session: session)
        viewModel.query = query
        return viewModel
    }
}

/// Runs the search once, so the preview shows a person found (or the error).
private struct AdminUsersPreviewHost: View {
    let viewModel: AdminUsersViewModel

    var body: some View {
        NavigationStack { AdminUsersView(viewModel: viewModel) }
            .task { await viewModel.searchSubmitted() }
    }
}

#Preview("Found") { AdminUsersPreviewHost(viewModel: .preview(query: SampleSocialData.kabir.username)) }
#Preview("Start") { NavigationStack { AdminUsersView(viewModel: .preview()) } }
#Preview("Error") { AdminUsersPreviewHost(viewModel: .preview(.failing, query: "sample")) }
#Preview("Not team") { NavigationStack { AdminUsersView(viewModel: .preview(team: false)) } }
#Preview("Large text") {
    AdminUsersPreviewHost(viewModel: .preview(query: SampleSocialData.kabir.username))
        .dynamicTypeSize(.accessibility3)
}
#endif
