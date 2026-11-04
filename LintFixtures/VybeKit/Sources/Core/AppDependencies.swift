// Fixture: AppDependencies.preview may be @MainActor; other members may not.
public struct AppDependencies {
    @MainActor public static let preview = AppDependencies()
    @MainActor public static var live: AppDependencies { AppDependencies() } // expect: main_actor_in_core
}
