import Core
import Models
import Testing
@testable import HangoutDetailFeature

/// Builds every entry point of `HangoutDetailScreens` (task F-16).
@MainActor
struct HangoutDetailScreensTests {
    @Test func everyEntryPointBuilds() {
        let deps = AppDependencies.preview(.loaded)
        _ = HangoutDetailScreens.view(for: .detail("h1"), deps)
        _ = HangoutDetailScreens.view(for: .remixTree("h1"), deps)
        _ = HangoutDetailScreens.spotSheet("p1", deps)
    }
}
