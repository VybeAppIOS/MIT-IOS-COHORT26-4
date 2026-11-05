#if DEBUG
import Core
import Foundation
import SwiftUI

extension AccountBasicsViewModel {
    /// The real ViewModel on the `AuthRepository` stub ("sample.friend" is taken there).
    static func preview(username: String? = nil, blocked: Bool = false) -> AccountBasicsViewModel {
        let deps = AppDependencies.preview()
        let viewModel = AccountBasicsViewModel(auth: deps.auth, session: deps.session, router: deps.router,
                                               now: { Date() }, debounce: { _ in })
        if let username { viewModel.username = username }
        return viewModel
    }
}

private func screen(_ viewModel: AccountBasicsViewModel) -> some View {
    NavigationStack { AccountBasicsView(viewModel: viewModel) }
}

#Preview("Empty") { screen(.preview()) }
#Preview("Available") { screen(.preview(username: "riya.k")) }
#Preview("Taken") { screen(.preview(username: "sample.friend")) }
#Preview("Rule error") { screen(.preview(username: "ri")) }
#Preview("Under 18") {
    let viewModel = AccountBasicsViewModel.preview(username: "riya.k")
    screen(viewModel).task {
        await viewModel.waitForCheck()
        viewModel.birthDate = Calendar.current.date(byAdding: .year, value: -15, to: Date()) ?? Date()
        await viewModel.continueTapped()
    }
}
#Preview("Large text") { screen(.preview(username: "riya.k")).dynamicTypeSize(.accessibility3) }
#endif
