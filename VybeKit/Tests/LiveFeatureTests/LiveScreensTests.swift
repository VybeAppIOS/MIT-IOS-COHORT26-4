import Core
import Models
import Testing
@testable import LiveFeature

/// Builds every entry point of `LiveScreens` (task F-16).
@MainActor
struct LiveScreensTests {
    @Test func everyEntryPointBuilds() {
        let deps = AppDependencies.preview(.loaded)
        _ = LiveScreens.liveCover("h1", deps)
        _ = LiveScreens.view(for: .summary("r1"), deps)
    }
}
