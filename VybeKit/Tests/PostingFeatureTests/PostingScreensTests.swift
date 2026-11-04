import Core
import Models
import Testing
@testable import PostingFeature

/// Builds every entry point of `PostingScreens` (task F-16).
@MainActor
struct PostingScreensTests {
    @Test func everyEntryPointBuilds() {
        let deps = AppDependencies.preview(.loaded)
        _ = PostingScreens.view(for: .compose("r1"), deps)
        _ = PostingScreens.editPostSheet("r1", deps)
    }
}
