import Core
import Testing
@testable import DiscoverFeature

/// Builds every entry point of `DiscoverScreens` (task F-16).
@MainActor
struct DiscoverScreensTests {
    @Test func everyEntryPointBuilds() {
        let deps = AppDependencies.preview(.loaded)
        _ = DiscoverScreens.root(deps)
    }
}
