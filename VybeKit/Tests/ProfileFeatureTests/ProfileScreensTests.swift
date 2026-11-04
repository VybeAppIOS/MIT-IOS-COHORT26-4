import Core
import Testing
@testable import ProfileFeature

/// Builds every entry point of `ProfileScreens` (task F-16).
@MainActor
struct ProfileScreensTests {
    @Test func everyEntryPointBuilds() {
        let deps = AppDependencies.preview(.loaded)
        _ = ProfileScreens.root(deps)
        _ = ProfileScreens.view(for: .saved, deps)
        _ = ProfileScreens.view(for: .drafts, deps)
        _ = ProfileScreens.view(for: .readyToPost, deps)
        _ = ProfileScreens.view(for: .settings, deps)
        _ = ProfileScreens.view(for: .deleteAccount, deps)
    }

    @Test(arguments: SettingsPage.allCases)
    func everySettingsPageBuilds(page: SettingsPage) {
        _ = ProfileScreens.view(for: .settingsPage(page), AppDependencies.preview(.loaded))
    }
}
