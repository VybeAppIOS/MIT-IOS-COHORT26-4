// Fixture (must pass): the app's test target may use AppDependencies.preview (rule 16).
import Testing
@testable import Vybe

@MainActor struct AppDependenciesTests {
    @Test func previewBuilds() { _ = AppDependencies.preview }
}
