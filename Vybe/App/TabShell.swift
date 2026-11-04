import CommunityFeature
import Core
import DiscoverFeature
import ProfileFeature
import SearchFeature
import SwiftUI

/// The four tabs, one `NavigationStack` each, with Search as the separate search-role tab at the trailing end.
/// Hosts the router's sheet while no cover is up.
struct TabShell: View {
    /// Every tab the bar shows. The router's selected tab must always be one of these (iOS 27 can crash otherwise).
    static let visibleTabs: [AppTab] = [.discover, .community, .profile, .search]

    let deps: AppDependencies

    var body: some View {
        TabView(selection: deps.router.tabBinding) {
            Tab("Discover", systemImage: "map", value: AppTab.discover) {
                RoutedStack(stack: .tab(.discover), deps: deps) { DiscoverScreens.root(deps) }
            }
            Tab("Community", systemImage: "person.2", value: AppTab.community) {
                RoutedStack(stack: .tab(.community), deps: deps) { CommunityScreens.root(deps) }
            }
            Tab("Profile", systemImage: "person.crop.circle", value: AppTab.profile) {
                RoutedStack(stack: .tab(.profile), deps: deps) { ProfileScreens.root(deps) }
            }
            Tab(value: AppTab.search, role: .search) {
                RoutedStack(stack: .tab(.search), deps: deps) { SearchScreens.root(deps) }
            }
        }
        .modifier(RouterSheetHost(deps: deps, coverIsUp: false))
    }
}
