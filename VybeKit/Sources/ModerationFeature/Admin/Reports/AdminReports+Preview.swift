#if DEBUG
import Core
import Foundation
import Models
import SwiftUI

extension AdminReportsViewModel {
    /// The real ViewModel on the stubs. `team: false` shows what everyone else sees.
    static func preview(_ mode: StubMode = .loaded, team: Bool = true) -> AdminReportsViewModel {
        let deps = AppDependencies.preview(mode)
        let session = SessionStore(settings: AppSettings(suiteName: "vybe.preview.admin"),
                                   currentUser: SampleData.signedInUser, isTeamAccount: team)
        return AdminReportsViewModel(admin: deps.admin, session: session, router: deps.router, now: deps.now)
    }
}

#Preview("Loaded") { NavigationStack { AdminReportsView(viewModel: .preview()) } }
#Preview("Empty") { NavigationStack { AdminReportsView(viewModel: .preview(.empty)) } }
#Preview("Error") { NavigationStack { AdminReportsView(viewModel: .preview(.failing)) } }
#Preview("Not team") { NavigationStack { AdminReportsView(viewModel: .preview(team: false)) } }
#Preview("Large text") {
    NavigationStack { AdminReportsView(viewModel: .preview()) }
        .dynamicTypeSize(.accessibility3)
}
#endif
