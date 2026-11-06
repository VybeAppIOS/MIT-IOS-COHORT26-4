import Testing
@testable import Core

/// "There is a route for every screen in `docs/IA.md` section 4." Each row says how a screen is reached.
/// Add a row when a screen is added to the IA.
struct IACoverageTests {
    enum Presentation {
        case root          // the first screen of a tab or of the onboarding stack
        case local         // a sheet, card or dialog owned by one feature (a flag in its ViewModel)
        case route(Route)  // pushed through the router
        case sheet(Sheet)  // shown by the router's sheet host
        case cover(Cover)  // full-screen cover
        case overlay       // a view laid over other screens
    }

    static let screens: [(id: String, how: Presentation)] = [
        ("O1", .root), ("A1", .route(.signIn)), ("A2", .route(.emailSignIn)), ("A3", .route(.accountBasics)),
        ("O2", .route(.nameAndPhoto)), ("O3", .route(.interests)), ("O4", .route(.location)),
        ("O5", .route(.findFriends)),
        ("D1", .root), ("D2", .local), ("D3", .local),
        ("HD1", .route(.hangout("h1"))), ("HD2", .sheet(.spot("p1"))), ("HD3", .route(.remixTree("h1"))),
        ("E1", .cover(.editor(.new))), ("E2", .local), ("E3", .sheet(.suggestPlace)),
        ("H1", .cover(.live("h1"))), ("H2", .local), ("H3", .route(.liveSummary("r1"))), ("H4", .overlay),
        ("PO1", .route(.composePost("r1"))), ("PO2", .sheet(.editPost("r1"))),
        ("CM1", .root), ("CM2", .route(.post("r1"))), ("CM3", .local), ("CM4", .route(.trending)),
        ("CM5", .route(.activity)), ("FR1", .route(.friendsHub)),
        ("CH1", .route(.chatList)), ("CH2", .route(.conversation("c1"))), ("CH3", .local),
        ("CH4", .route(.groupInfo("c1"))), ("CH5", .sheet(.share(.hangout("h1")))), ("CH6", .local),
        ("CH7", .sheet(.groupInvitation("c1"))), ("CH8", .route(.groupPhotos("c1"))),
        ("PR1", .root), ("PR2", .route(.settings)), ("PR3", .route(.profile("u1"))), ("PR4", .route(.saved)),
        ("PR5", .route(.drafts)), ("PR6", .local), ("PR7", .route(.mutualFriends("u1"))),
        ("PR8", .route(.readyToPost)),
        ("ST1", .route(.settingsPage(.account))), ("ST2", .route(.settingsPage(.privacy))),
        ("ST3", .route(.settingsPage(.blocked))), ("ST4", .route(.settingsPage(.notifications))),
        ("ST5", .route(.settingsPage(.help))), ("ST6", .route(.settingsPage(.placeSuggestions))),
        ("ST7", .route(.settingsPage(.about))), ("ST8", .route(.deleteAccount)),
        ("S1", .root), ("S2", .route(.searchSeeAll(.hangouts))),
        ("AD1", .route(.admin(.reports))), ("AD2", .route(.admin(.placeSuggestions))),
        ("AD3", .route(.admin(.users))),
        ("R1", .sheet(.report(.place("p1")))), ("R2", .sheet(.blockConfirm("u1"))), ("X1", .overlay)
    ]

    @Test func everyPushedScreenInTheIAHasARouteThatIsListedForCoding() {
        let routes = Set(RouteCodingTests.allRoutes)
        for (id, how) in Self.screens {
            switch how {
            case .route(let route): #expect(routes.contains(route), "\(id): route missing from the coding list")
            case .sheet(let sheet): #expect(RouteCodingTests.allSheets.contains(sheet), "\(id)")
            case .cover(let cover): #expect(RouteCodingTests.allCovers.contains(cover), "\(id)")
            case .root, .local, .overlay: break
            }
        }
    }

    @Test func everyScreenIDInTheIAIsListedOnce() {
        let ids = Self.screens.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(ids.count == 61)   // every screen in `docs/IA.md` section 4 except the WEB1 web page
    }
}
