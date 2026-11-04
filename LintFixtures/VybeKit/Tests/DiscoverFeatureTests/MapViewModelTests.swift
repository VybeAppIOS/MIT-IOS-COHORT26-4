// Fixture (must pass): tests may use AppDependencies.preview (rule 16).
import Testing
@testable import DiscoverFeature

@MainActor struct MapViewModelTests {
    @Test func loadsPins() async {
        let deps = AppDependencies.preview
        _ = deps
    }
}
