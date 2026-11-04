import Core
import Models
import Testing
@testable import Vybe

/// Task X-14: the debug launch options. These tests only exist in DEBUG builds, like the options themselves.
@MainActor
struct LaunchOptionsTests {
    private func options(_ arguments: String...) -> LaunchOptions {
        LaunchOptions(arguments: ["/path/to/Vybe"] + arguments)
    }

    // MARK: Flags and modes

    @Test func noArgumentsMeansNoOptions() {
        let none = options()
        #expect(none.stubMode == nil && none.destination == nil)
        #expect(!none.skipOnboarding && !none.resetState && !none.simulateWalk)
    }

    @Test func flagsAreRead() {
        let all = options("-skipOnboarding", "-resetState", "-simulateWalk")
        #expect(all.skipOnboarding && all.resetState && all.simulateWalk)
    }

    @Test(arguments: [("loaded", StubMode.loaded), ("empty", .empty), ("failing", .failing), ("loading", .neverReturns),
                      ("LOADED", .loaded)])
    func stubModesAreRead(name: String, expected: StubMode) {
        #expect(options("-stubMode", name).stubMode == expected)
    }

    @Test func anUnknownModeOrAMissingValueIsIgnored() {
        #expect(options("-stubMode", "banana").stubMode == nil)
        #expect(options("-stubMode").stubMode == nil)
        #expect(options("-debugRoute").destination == nil)
    }

    @Test func optionsMayComeInAnyOrderWithOtherArguments() {
        let mixed = options("-AppleLanguages", "(en)", "-debugRoute", "saved", "-skipOnboarding",
                            "-stubMode", "empty")
        #expect(mixed.destination == .route(.saved) && mixed.skipOnboarding && mixed.stubMode == .empty)
    }

    // MARK: Short forms

    @Test(arguments: [
        ("hangout/hangout-example-evening-c3d4", DebugDestination.route(.hangout("hangout-example-evening-c3d4"))),
        ("remix-tree/h1", .route(.remixTree("h1"))), ("live-summary/r1", .route(.liveSummary("r1"))),
        ("compose-post/r1", .route(.composePost("r1"))), ("post/r1", .route(.post("r1"))),
        ("profile/u1", .route(.profile("u1"))), ("mutual-friends/u1", .route(.mutualFriends("u1"))),
        ("conversation/c1", .route(.conversation("c1"))), ("group-info/c1", .route(.groupInfo("c1"))),
        ("saved", .route(.saved)), ("drafts", .route(.drafts)), ("ready-to-post", .route(.readyToPost)),
        ("settings", .route(.settings)), ("settings/privacy", .route(.settingsPage(.privacy))),
        ("settings/place-suggestions", .route(.settingsPage(.placeSuggestions))),
        ("delete-account", .route(.deleteAccount)), ("trending", .route(.trending)), ("activity", .route(.activity)),
        ("friends", .route(.friendsHub)), ("chats", .route(.chatList)), ("suggest-place", .route(.suggestPlace)),
        ("see-all/people", .route(.searchSeeAll(.people))), ("admin/reports", .route(.admin(.reports))),
        ("report/comment/c1", .route(.report(.comment("c1")))), ("sign-in", .route(.signIn)),
        ("email-sign-in", .route(.emailSignIn)), ("account-basics", .route(.accountBasics)),
        ("name-and-photo", .route(.nameAndPhoto)), ("interests", .route(.interests)),
        ("location", .route(.location)), ("find-friends", .route(.findFriends))
    ])
    func routeShortFormsParse(text: String, expected: DebugDestination) {
        #expect(DebugDestination(parsing: text) == expected)
    }

    @Test(arguments: [
        ("sheet/spot/p1", DebugDestination.sheet(.spot("p1"))), ("sheet/suggest-place", .sheet(.suggestPlace)),
        ("sheet/edit-post/r1", .sheet(.editPost("r1"))),
        ("sheet/group-invitation/c1", .sheet(.groupInvitation("c1"))),
        ("sheet/report/user/u1", .sheet(.report(.user("u1")))),
        ("sheet/share/hangout/h1", .sheet(.share(.hangout("h1")))),
        ("sheet/share/post/r1", .sheet(.share(.post("r1")))),
        ("cover/live/h1", .cover(.live("h1"))),
        ("cover/editor/new", .cover(.editor(.new))), ("cover/editor/draft/h1", .cover(.editor(.draft("h1")))),
        ("cover/editor/remix/h1", .cover(.editor(.remix("h1"))))
    ])
    func sheetAndCoverShortFormsParse(text: String, expected: DebugDestination) {
        #expect(DebugDestination(parsing: text) == expected)
    }

    @Test(arguments: [
        "", "  ", "nonsense", "hangout", "hangout/", "settings/nowhere", "report/banana/x", "see-all/cats", "sheet/",
        "sheet/spot", "cover/editor", "cover/editor/sideways", "hangout/a/b", "{not json"
    ])
    func nonsenseIsRejected(text: String) {
        #expect(DebugDestination(parsing: text) == nil)
    }

    @Test func extraSpacesAndSlashesAreForgiven() {
        #expect(DebugDestination(parsing: "  hangout/h1  ") == .route(.hangout("h1")))
        #expect(DebugDestination(parsing: "/saved/") == .route(.saved))
    }

    // MARK: JSON

    @Test func aJSONRouteIsRead() throws {
        let route = Route.hangout("hangout-example-evening-c3d4")
        let json = String(bytes: try JSONCoding.encoder.encode(route), encoding: .utf8) ?? ""
        #expect(DebugDestination(parsing: json) == .route(route))
    }

    @Test func everyRouteSurvivesTheJSONForm() throws {
        for route in [Route.saved, .settingsPage(.about), .report(.user("u1")), .conversation("c1"), .signIn] {
            let json = String(bytes: try JSONCoding.encoder.encode(route), encoding: .utf8) ?? ""
            #expect(DebugDestination(parsing: json) == .route(route))
        }
    }

    // MARK: Opening a screen

    @Test func aRouteOpensInItsOwnTab() {
        let deps = AppDependencies.preview(.loaded)
        options("-debugRoute", "settings").apply(to: deps)
        #expect(deps.router.selectedTab == .profile)
        #expect(deps.router.path(for: .tab(.profile)) == [.settings])

        let other = AppDependencies.preview(.loaded)
        options("-debugRoute", "hangout/h1").apply(to: other)
        #expect(other.router.selectedTab == .discover && other.router.path(for: .tab(.discover)) == [.hangout("h1")])
    }

    @Test(arguments: [
        (Route.signIn, AppTab?.none), (.nameAndPhoto, nil), (.hangout("h"), .discover), (.liveSummary("r"), .discover),
        (.composePost("r"), .discover), (.suggestPlace, .discover), (.searchSeeAll(.places), .search),
        (.post("r"), .community), (.friendsHub, .community), (.profile("u"), .community), (.chatList, .community),
        (.saved, .profile), (.settings, .profile), (.report(.user("u")), .profile), (.admin(.users), .profile)
    ])
    func everyRouteHasAHomeTab(route: Route, tab: AppTab?) {
        #expect(LaunchOptions.tab(for: route) == tab)
    }

    @Test func anOnboardingRouteOpensOnTheOnboardingStack() {
        let deps = AppDependencies.preview(.loaded)
        options("-debugRoute", "interests").apply(to: deps)
        #expect(deps.router.isOnboarding && deps.router.path(for: .onboarding) == [.interests])
    }

    @Test func sheetsAndCoversArePresented() {
        let sheetDeps = AppDependencies.preview(.loaded)
        options("-debugRoute", "sheet/spot/p1").apply(to: sheetDeps)
        #expect(sheetDeps.router.sheet == .spot("p1"))

        let coverDeps = AppDependencies.preview(.loaded)
        options("-debugRoute", "cover/live/h1").apply(to: coverDeps)
        #expect(coverDeps.router.cover == .live("h1"))
    }

    @Test func noRouteChangesNothing() {
        let deps = AppDependencies.preview(.loaded)
        options("-stubMode", "empty").apply(to: deps)
        #expect(deps.router.paths.isEmpty && deps.router.sheet == nil && deps.router.cover == nil)
    }

    /// The point of `-debugRoute`: the real screen factory can build what it opens.
    @Test func everyShortFormOpensAScreenTheFactoryCanBuild() {
        let factory = ScreenFactory(deps: .preview(.loaded))
        for text in ["hangout/h1", "settings/privacy", "report/user/u1", "conversation/c1", "admin/users"] {
            guard case .route(let route) = DebugDestination(parsing: text) else {
                Issue.record("\(text) did not parse to a route")
                continue
            }
            _ = factory.screen(for: route)
        }
    }
}
