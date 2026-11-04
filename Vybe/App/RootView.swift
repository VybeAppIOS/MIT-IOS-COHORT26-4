import Core
import OnboardingFeature
import SwiftUI

/// The first view. Shows onboarding until it is done, then the tabs; hosts the full-screen covers.
struct RootView: View {
    @State private var deps: AppDependencies

    /// Pass dependencies for previews and tests; the app uses `AppDependencies.local()`.
    init(deps: AppDependencies? = nil) {
        _deps = State(initialValue: deps ?? .local())
    }

    var body: some View {
        Group {
            if deps.session.onboardingDone {
                TabShell(deps: deps)
            } else {
                RoutedStack(stack: .onboarding, deps: deps) { OnboardingScreens.root(deps) }
            }
        }
        .fullScreenCover(item: deps.router.coverBinding) { cover in
            RoutedStack(stack: Self.stack(for: cover), deps: deps) { ScreenFactory(deps: deps).cover(for: cover) }
                .modifier(RouterSheetHost(deps: deps, coverIsUp: true))
        }
        .onAppear { deps.router.setOnboarding(!deps.session.onboardingDone) }
        .onChange(of: deps.session.onboardingDone) { _, done in
            if done { deps.router.reset() } else { deps.router.setOnboarding(true) }
        }
    }

    private static func stack(for cover: Cover) -> StackID {
        switch cover {
        case .live: .live
        case .editor: .editor
        }
    }
}

#Preview("Tabs") {
    RootView(deps: .preview(.loaded))
}
