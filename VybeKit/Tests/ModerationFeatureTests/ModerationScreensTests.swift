import Core
import Models
import Testing
@testable import ModerationFeature

/// Builds every entry point of `ModerationScreens` (task F-16).
@MainActor
struct ModerationScreensTests {
    @Test func everyEntryPointBuilds() {
        let deps = AppDependencies.preview(.loaded)
        _ = ModerationScreens.view(for: .report(.place("p1")), deps)
        _ = ModerationScreens.view(for: .admin(.reports), deps)
        _ = ModerationScreens.view(for: .admin(.placeSuggestions), deps)
        _ = ModerationScreens.view(for: .admin(.users), deps)
        _ = ModerationScreens.reportSheet(.user("u1"), deps)
    }
}
