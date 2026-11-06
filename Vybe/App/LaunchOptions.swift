#if DEBUG
import Core
import Foundation
import LocalData
import Models

/// Debug launch options (task X-14, ADR 006). They exist only in DEBUG builds: a Release build does not contain this
/// file, so nobody can open arbitrary screens or reset data with them. They let a person, a test or an AI agent open
/// exactly one screen in exactly one state and take a screenshot of it (`scripts/snap.sh`).
///
///     -stubMode loaded|empty|failing|loading   run the whole app on the sample stubs in that state
///     -debugRoute <JSON Route | short form>    open one screen, for example  hangout/hangout-example-evening-c3d4
///     -tab discover|community|profile|search   start on that tab (for example the Profile tab's own screen)
///     -teamAccount                             act as a team account (the hidden admin pages open)
///     -skipOnboarding                          go straight to the tabs
///     -resetState                              forget saved settings, library and profile first
///     -simulateWalk                            use the simulated walk instead of the real GPS
@MainActor
struct LaunchOptions: Equatable {
    var stubMode: StubMode?
    var destination: DebugDestination?
    var tab: AppTab?
    var skipOnboarding = false
    var teamAccount = false
    var resetState = false
    var simulateWalk = false

    /// The options this run of the app was started with.
    static let current = LaunchOptions(arguments: ProcessInfo.processInfo.arguments)

    init(arguments: [String]) {
        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            let value = index + 1 < arguments.count ? arguments[index + 1] : nil
            switch argument {
            case "-stubMode":
                stubMode = value.flatMap(Self.mode(named:))
                index += 1
            case "-tab":
                tab = value.flatMap { name in AppTab.allCases.first { String(describing: $0) == name } }
                index += 1
            case "-debugRoute":
                destination = value.flatMap(DebugDestination.init(parsing:))
                index += 1
            case "-skipOnboarding": skipOnboarding = true
            case "-teamAccount": teamAccount = true
            case "-resetState": resetState = true
            case "-simulateWalk": simulateWalk = true
            default: break
            }
            index += 1
        }
    }

    /// `loading` is the "never answers" stub.
    static func mode(named name: String) -> StubMode? {
        switch name.lowercased() {
        case "loaded": .loaded
        case "empty": .empty
        case "failing": .failing
        case "loading": .neverReturns
        default: nil
        }
    }

    /// Runs before the app's dependencies are built: forget saved data, then skip onboarding if asked.
    func prepareState() {
        if resetState {
            AppSettings().clear()
            for url in [LocalDataPaths.libraryURL, LocalDataPaths.profileURL] {
                try? FileManager.default.removeItem(at: url)
            }
        }
        if skipOnboarding { AppSettings().onboardingDone = true }
    }

    /// Opens the requested screen. Call it once the first screen is up.
    func apply(to deps: AppDependencies) {
        if teamAccount { deps.session.debugSetTeamAccount(true) }
        if let tab { deps.router.selectedTab = tab }
        guard let destination else { return }
        switch destination {
        case .route(let route):
            if let tab = Self.tab(for: route) {
                deps.router.show(route, in: tab)
            } else {
                deps.router.setOnboarding(true)
                deps.router.open(route)
            }
        case .sheet(let sheet): deps.router.present(sheet)
        case .cover(let cover): deps.router.presentCover(cover)
        }
    }

    /// The tab a route is shown in. Nil means the onboarding flow.
    static func tab(for route: Route) -> AppTab? {
        switch route {
        case .onboarding, .auth: nil
        case .search: .search
        case .community, .friends, .chat: .community
        case .profile, .moderation: .profile
        case .hangoutDetail, .live, .posting, .editor: .discover
        }
    }
}

/// What `-debugRoute` can open: a pushed screen, a sheet or a full-screen cover.
@MainActor
enum DebugDestination: Equatable {
    case route(Route)
    case sheet(Sheet)
    case cover(Cover)

    /// A JSON `Route` (as the app encodes it), or a short form such as `hangout/<id>`, `settings/privacy`,
    /// `sheet/spot/<id>`, `cover/live/<id>`. Nil if it is neither.
    init?(parsing text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("{") {
            guard let route = try? JSONCoding.decoder.decode(Route.self, from: Data(trimmed.utf8)) else { return nil }
            self = .route(route)
            return
        }
        let parts = trimmed.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
        guard let first = parts.first else { return nil }
        let rest = Array(parts.dropFirst())
        switch first {
        case "sheet":
            guard let sheet = Self.sheet(rest) else { return nil }
            self = .sheet(sheet)
        case "cover":
            guard let cover = Self.cover(rest) else { return nil }
            self = .cover(cover)
        default:
            guard let route = Self.route(parts) else { return nil }
            self = .route(route)
        }
    }

    // MARK: Short forms

    /// Screens that need nothing else: `settings`, `saved`, `sign-in` ...
    private static let plainRoutes: [String: Route] = [
        "sign-in": .signIn, "email-sign-in": .emailSignIn, "account-basics": .accountBasics,
        "name-and-photo": .nameAndPhoto, "interests": .interests, "location": .location,
        "find-friends": .findFriends, "saved": .saved, "drafts": .drafts, "ready-to-post": .readyToPost,
        "settings": .settings, "delete-account": .deleteAccount, "trending": .trending, "activity": .activity,
        "friends": .friendsHub, "chats": .chatList, "suggest-place": .suggestPlace
    ]

    /// Screens opened with one ID: `hangout/<id>`, `post/<id>` ...
    private static let routesWithID: [String: @Sendable (String) -> Route] = [
        "hangout": { .hangout(HangoutID($0)) }, "remix-tree": { .remixTree(HangoutID($0)) },
        "live-summary": { .liveSummary(RunID($0)) }, "compose-post": { .composePost(RunID($0)) },
        "post": { .post(RunID($0)) }, "profile": { .profile(UserID($0)) },
        "mutual-friends": { .mutualFriends(UserID($0)) }, "conversation": { .conversation(ConversationID($0)) },
        "group-info": { .groupInfo(ConversationID($0)) }, "group-photos": { .groupPhotos(ConversationID($0)) }
    ]

    private static func route(_ parts: [String]) -> Route? {
        guard let name = parts.first else { return nil }
        switch parts.count {
        case 1: return plainRoutes[name]
        case 2: return routesWithID[name]?(parts[1]) ?? namedRoute(name, parts[1])
        case 3 where name == "report": return reportTarget(parts[1], parts[2]).map { .report($0) }
        default: return nil
        }
    }

    /// `settings/<page>`, `see-all/<group>`, `admin/<page>`.
    private static func namedRoute(_ name: String, _ argument: String) -> Route? {
        switch name {
        case "settings": settingsPage(argument).map { .settingsPage($0) }
        case "see-all": searchKind(argument).map { .searchSeeAll($0) }
        case "admin": adminPage(argument).map { .admin($0) }
        default: nil
        }
    }

    private static let sheetsWithID: [String: @Sendable (String) -> Sheet] = [
        "spot": { .spot(PlaceID($0)) }, "edit-post": { .editPost(RunID($0)) },
        "group-invitation": { .groupInvitation(ConversationID($0)) }, "block": { .blockConfirm(UserID($0)) }
    ]

    private static func sheet(_ parts: [String]) -> Sheet? {
        guard let name = parts.first else { return nil }
        switch parts.count {
        case 1: return name == "suggest-place" ? .suggestPlace : nil
        case 2: return sheetsWithID[name]?(parts[1])
        case 3 where name == "report": return reportTarget(parts[1], parts[2]).map { .report($0) }
        case 3 where name == "share": return shareItem(parts[1], parts[2]).map { .share($0) }
        default: return nil
        }
    }

    private static func shareItem(_ kind: String, _ id: String) -> ShareItem? {
        switch kind {
        case "hangout": .hangout(HangoutID(id))
        case "post": .post(RunID(id))
        default: nil
        }
    }

    private static func cover(_ parts: [String]) -> Cover? {
        switch (parts.first, parts.count) {
        case ("live", 2): return .live(HangoutID(parts[1]))
        case ("editor", 2) where parts[1] == "new": return .editor(.new)
        case ("editor", 3) where parts[1] == "draft": return .editor(.draft(HangoutID(parts[2])))
        case ("editor", 3) where parts[1] == "remix": return .editor(.remix(HangoutID(parts[2])))
        default: return nil
        }
    }

    private static func reportTarget(_ kind: String, _ id: String) -> ReportTarget? {
        switch kind {
        case "run": .run(RunID(id))
        case "comment": .comment(CommentID(id))
        case "user": .user(UserID(id))
        case "message": .message(MessageID(id))
        case "place": .place(PlaceID(id))
        case "hangout": .hangout(HangoutID(id))
        default: nil
        }
    }

    private static func searchKind(_ name: String) -> SearchKind? {
        ["hangouts": .hangouts, "places": .places, "people": .people][name]
    }

    private static func settingsPage(_ name: String) -> SettingsPage? {
        ["account": .account, "privacy": .privacy, "blocked": .blocked, "notifications": .notifications,
         "help": .help, "place-suggestions": .placeSuggestions, "about": .about][name]
    }

    private static func adminPage(_ name: String) -> AdminPage? {
        ["reports": .reports, "place-suggestions": .placeSuggestions, "users": .users][name]
    }
}
#endif
