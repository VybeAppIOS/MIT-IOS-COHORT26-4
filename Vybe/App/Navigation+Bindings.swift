import Core
import SwiftUI

/// Turns the router's state into the bindings SwiftUI needs. Reading goes to the router; writing goes through
/// its methods, so a back swipe or a swipe-down reaches the router (ADR 003).
extension Router {
    func pathBinding(for stack: StackID) -> Binding<[Route]> {
        Binding(get: { self.path(for: stack) }, set: { self.setPath($0, for: stack) })
    }

    /// The router's sheet, only for the host that is allowed to show it right now.
    func sheetBinding(whileCoverIsUp coverIsUp: Bool) -> Binding<Sheet?> {
        Binding(
            get: { (self.cover != nil) == coverIsUp ? self.sheet : nil },
            set: { if $0 == nil { self.dismissSheet() } })
    }

    var coverBinding: Binding<Cover?> {
        Binding(get: { self.cover }, set: { if $0 == nil { self.dismissCover() } })
    }

    var tabBinding: Binding<AppTab> {
        Binding(get: { self.selectedTab }, set: { self.selectedTab = $0 })
    }
}

/// A `NavigationStack` bound to one of the router's stacks, with the route destinations every stack needs.
struct RoutedStack<Root: View>: View {
    let stack: StackID
    let deps: AppDependencies
    @ViewBuilder let root: () -> Root

    var body: some View {
        NavigationStack(path: deps.router.pathBinding(for: stack)) {
            root().navigationDestination(for: Route.self) { route in
                ScreenFactory(deps: deps).screen(for: route)
            }
        }
    }
}

/// The router's sheet host: the sheet's content with its own stack (`StackID.sheet`), so Report can be pushed
/// inside the Spot sheet.
struct RouterSheetHost: ViewModifier {
    let deps: AppDependencies
    let coverIsUp: Bool

    func body(content: Content) -> some View {
        content.sheet(item: deps.router.sheetBinding(whileCoverIsUp: coverIsUp)) { sheet in
            RoutedStack(stack: .sheet, deps: deps) { ScreenFactory(deps: deps).sheet(for: sheet) }
        }
    }
}
