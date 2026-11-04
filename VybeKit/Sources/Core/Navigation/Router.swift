import Foundation
import Observation

/// The one place that knows what is on screen. ViewModels call its methods; they never write its properties
/// (`AGENTS.md` 5). It has no SwiftUI: the App's hosts turn `paths` into `NavigationStack` bindings (ADR 003).
@MainActor @Observable
public final class Router {
    public var selectedTab: AppTab = .discover {
        didSet { if selectedTab != .search { lastNonSearchTab = selectedTab } }
    }
    /// Every stack's current pages: tabs, onboarding, each cover and the sheet.
    public private(set) var paths: [StackID: [Route]] = [:]
    public private(set) var cover: Cover?
    public private(set) var sheet: Sheet?
    /// True while the onboarding flow is on screen instead of the tabs, so `open` pushes onto the onboarding stack.
    public private(set) var isOnboarding = false
    /// The last tab that was not Search; Search ranks its results by it.
    public private(set) var lastNonSearchTab: AppTab = .discover

    public init() {}

    /// The stack that is on screen: the sheet's if one is up, else the cover's, else onboarding's, else the tab's.
    public var currentStack: StackID {
        if sheet != nil { return .sheet }
        if let cover { return Self.stack(for: cover) }
        return isOnboarding ? .onboarding : .tab(selectedTab)
    }

    public func path(for stack: StackID) -> [Route] { paths[stack] ?? [] }

    /// Push onto the stack that is on screen.
    public func open(_ route: Route) { paths[currentStack, default: []].append(route) }

    public func pop() { _ = paths[currentStack]?.popLast() }

    public func popToRoot() { paths[currentStack] = [] }

    /// The system popped or changed a stack (back swipe): the host writes the new path back, because the
    /// system needs a writable binding and `paths` can only be set here.
    public func setPath(_ path: [Route], for stack: StackID) { paths[stack] = path }

    public func present(_ sheet: Sheet) {
        self.sheet = sheet
        paths[.sheet] = []
    }

    /// Closes the sheet and the pages pushed inside it.
    public func dismissSheet() {
        sheet = nil
        paths[.sheet] = nil
    }

    /// Opens a full-screen cover. A sheet that is up closes first: otherwise the cover's own sheet host would show
    /// that old sheet again on top of the cover.
    public func presentCover(_ cover: Cover) {
        dismissSheet()
        self.cover = cover
    }

    /// Closes the cover (and clears its stack) and any sheet.
    public func dismissCover() {
        if let cover { paths[Self.stack(for: cover)] = [] }
        cover = nil
        dismissSheet()
    }

    /// Leave whatever is up and show a screen in a tab
    /// (post made, then show it in Community; editor Done, then Drafts).
    public func show(_ route: Route?, in tab: AppTab) {
        dismissCover()
        isOnboarding = false
        selectedTab = tab
        paths[.tab(tab)] = route.map { [$0] } ?? []
    }

    /// Switch between the onboarding flow and the tabs. Starting it begins on an empty onboarding stack.
    public func setOnboarding(_ active: Bool) {
        isOnboarding = active
        if active { paths[.onboarding] = [] }
    }

    /// Sign out, account deletion, "reset onboarding": clear every stack, sheet and cover.
    public func reset() {
        paths = [:]
        cover = nil
        sheet = nil
        isOnboarding = false
        selectedTab = .discover
    }

    private static func stack(for cover: Cover) -> StackID {
        switch cover {
        case .live: .live
        case .editor: .editor
        }
    }
}
