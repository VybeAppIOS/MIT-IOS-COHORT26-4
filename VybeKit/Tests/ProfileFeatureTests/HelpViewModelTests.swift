import Core
import Models
import Testing
@testable import ProfileFeature

@MainActor
struct HelpViewModelTests {
    @Test func everyLineHasRealWords() {
        let viewModel = HelpViewModel(router: AppDependencies.preview().router)
        for text in [viewModel.title, viewModel.intro, viewModel.grievanceLabel, viewModel.pendingValue,
                     viewModel.termsLabel, viewModel.privacyLabel, viewModel.reportSubtitle] {
            #expect(!text.isEmpty && !text.hasPrefix("profile."))
        }
    }

    @Test func blockedPeopleOpensTheBlockedPage() {
        let deps = AppDependencies.preview()
        deps.router.selectedTab = .profile
        HelpViewModel(router: deps.router).blockedTapped()
        #expect(deps.router.path(for: .tab(.profile)) == [.settingsPage(.blocked)])
    }
}
