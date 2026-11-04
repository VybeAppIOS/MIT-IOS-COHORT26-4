import Core
import Models
import Testing
@testable import CommunityFeature

/// Builds every entry point of `CommunityScreens` (task F-16).
@MainActor
struct CommunityScreensTests {
    @Test func everyEntryPointBuilds() {
        let deps = AppDependencies.preview(.loaded)
        _ = CommunityScreens.root(deps)
        _ = CommunityScreens.view(for: .post("r1"), deps)
        _ = CommunityScreens.view(for: .trending, deps)
        _ = CommunityScreens.view(for: .activity, deps)
    }
}
