import Core
import Testing
@testable import SearchFeature

/// Builds every entry point of `SearchScreens` (task F-16).
@MainActor
struct SearchScreensTests {
    @Test func everyEntryPointBuilds() {
        let deps = AppDependencies.preview(.loaded)
        _ = SearchScreens.root(deps)
        _ = SearchScreens.view(for: .seeAll(.hangouts), deps)
    }
}
