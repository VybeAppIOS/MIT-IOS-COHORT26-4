// Fixture (must pass): the feature's Screens file may be public and may use AppDependencies.
import SwiftUI

public enum DiscoverScreens {
    @MainActor public static func make(_ deps: AppDependencies) -> some View { MapView(deps: deps) }
}
