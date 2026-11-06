#if DEBUG
import Core
import Foundation
import Models
import SwiftUI

extension AdminSuggestionsViewModel {
    /// The real ViewModel on the stubs, signed in as a team account unless `team` is false.
    static func preview(_ mode: StubMode = .loaded, team: Bool = true) -> AdminSuggestionsViewModel {
        let deps = AppDependencies.preview(mode)
        let session = SessionStore(settings: AppSettings(suiteName: "vybe.preview.admin"),
                                   currentUser: SampleData.signedInUser, isTeamAccount: team)
        return AdminSuggestionsViewModel(admin: deps.admin, session: session, now: deps.now)
    }
}

#Preview("Loaded") { NavigationStack { AdminSuggestionsView(viewModel: .preview()) } }
#Preview("Empty") { NavigationStack { AdminSuggestionsView(viewModel: .preview(.empty)) } }
#Preview("Error") { NavigationStack { AdminSuggestionsView(viewModel: .preview(.failing)) } }
#Preview("Not team") { NavigationStack { AdminSuggestionsView(viewModel: .preview(team: false)) } }
#Preview("Large text") {
    NavigationStack { AdminSuggestionsView(viewModel: .preview()) }
        .dynamicTypeSize(.accessibility3)
}
#endif
