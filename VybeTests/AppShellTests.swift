import Core
import Models
import Testing
@testable import Vybe

/// Task F-9: the shell maps every route, sheet and cover to the owning feature's `Screens`.
/// A placeholder carries its screen ID, so the text of the built view shows which screen was chosen.
@MainActor
struct AppShellTests {
    private let factory = ScreenFactory(deps: .preview(.loaded))

    private func describe(_ view: some Any) -> String { String(describing: view) }

    /// A placeholder is found by its quoted screen ID. A screen that has been built is found by its type name:
    /// write `"view:ReportView"` in the tables below when a screen task replaces its placeholder.
    private func reaches(_ view: some Any, _ expected: String) -> Bool {
        let text = describe(view)
        if expected.hasPrefix("view:") { return text.contains(expected.dropFirst("view:".count)) }
        return text.contains("\"\(expected)\"")
    }

    @Test func aHangoutRouteResolvesThroughHangoutDetailScreens() {
        #expect(reaches(factory.screen(for: .hangout("h1")), "view:HangoutDetailView"))
    }

    @Test(arguments: [
        (Route.signIn, "view:SignInView"), (.nameAndPhoto, "view:NameAndPhotoView"),
        (.remixTree("h1"), "view:RemixTreeView"),
        (.liveSummary("r1"), "view:SummaryView"),
        (.composePost("r1"), "view:ComposerView"), (.searchSeeAll(.places), "S2"), (.saved, "view:SavedView"),
        (.settingsPage(.privacy), "ST2"), (.post("r1"), "CM2"), (.friendsHub, "FR1"), (.profile("u1"), "PR3"),
        (.conversation("c1"), "CH2"), (.report(.user("u1")), "view:ReportView"),
        (.admin(.users), "view:AdminUsersView"),
        (.suggestPlace, "view:SuggestPlaceView"), (.settings, "view:SettingsView"),
        (.settingsPage(.account), "view:AccountSettingsView"), (.deleteAccount, "view:DeleteAccountView"),
        (.settingsPage(.help), "view:HelpView"), (.settingsPage(.placeSuggestions), "view:MySuggestionsView"),
        (.settingsPage(.about), "view:AboutView"), (.drafts, "view:DraftsView"),
        (.settingsPage(.blocked), "view:BlockedView"), (.admin(.reports), "view:AdminReportsView"),
        (.admin(.placeSuggestions), "view:AdminSuggestionsView"),
        (.readyToPost, "view:ReadyToPostView")
    ])
    func routesReachTheirScreen(route: Route, screenID: String) {
        #expect(reaches(factory.screen(for: route), screenID))
    }

    @Test(arguments: [
        (Sheet.spot("p1"), "view:SpotSheetView"), (.report(.place("p1")), "view:ReportView"),
        (.blockConfirm("u1"), "view:BlockConfirmView"), (.share(.post("r1")), "CH5"),
        (.suggestPlace, "view:SuggestPlaceView"), (.editPost("r1"), "view:EditPostView"),
        (.groupInvitation("c1"), "CH7")
    ])
    func sheetsReachTheirScreen(sheet: Sheet, screenID: String) {
        #expect(reaches(factory.sheet(for: sheet), screenID))
    }

    @Test func coversReachTheirScreen() {
        #expect(reaches(factory.cover(for: .live("h1")), "view:LiveView"))
        #expect(reaches(factory.cover(for: .editor(.new)), "view:EditorView"))
    }

    /// iOS 27 rule: the selected tab must always be a visible tab, and Search is last.
    @Test func everyTabTheRouterCanSelectIsVisible() {
        #expect(Set(TabShell.visibleTabs) == Set(AppTab.allCases))
        #expect(TabShell.visibleTabs.last == .search)
    }

    @Test func showSwitchesTabs() {
        let deps = AppDependencies.preview(.loaded)
        deps.router.show(.hangout("h1"), in: .profile)
        #expect(deps.router.selectedTab == .profile)
        #expect(deps.router.path(for: .tab(.profile)) == [.hangout("h1")])
    }

    @Test func coverBindingDismissesThroughTheRouter() {
        let deps = AppDependencies.preview(.loaded)
        deps.router.presentCover(.live("h1"))
        deps.router.open(.liveSummary("r1"))
        deps.router.coverBinding.wrappedValue = nil
        #expect(deps.router.cover == nil && deps.router.path(for: .live).isEmpty)
    }

    @Test func onlyTheAllowedHostSeesTheSheet() {
        let deps = AppDependencies.preview(.loaded)
        deps.router.present(.spot("p1"))
        #expect(deps.router.sheetBinding(whileCoverIsUp: false).wrappedValue == .spot("p1"))
        #expect(deps.router.sheetBinding(whileCoverIsUp: true).wrappedValue == nil)
        deps.router.presentCover(.live("h1"))
        deps.router.present(.spot("p1"))
        #expect(deps.router.sheetBinding(whileCoverIsUp: false).wrappedValue == nil)
        #expect(deps.router.sheetBinding(whileCoverIsUp: true).wrappedValue == .spot("p1"))
    }

    @Test func pathBindingWritesBackLikeABackSwipe() {
        let deps = AppDependencies.preview(.loaded)
        deps.router.open(.hangout("h1"))
        deps.router.open(.remixTree("h1"))
        deps.router.pathBinding(for: .tab(.discover)).wrappedValue = [.hangout("h1")]
        #expect(deps.router.path(for: .tab(.discover)) == [.hangout("h1")])
    }
}
