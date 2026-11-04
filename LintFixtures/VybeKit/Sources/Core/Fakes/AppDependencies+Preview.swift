// Fixture (must pass): AppDependencies.preview may be @MainActor, written on its own line (main_actor_in_core).
public extension AppDependencies {
    @MainActor
    static func preview(_ mode: StubMode = .loaded) -> AppDependencies {
        AppDependencies()
    }
}
