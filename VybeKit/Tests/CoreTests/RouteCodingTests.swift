import Foundation
import Models
import Testing
@testable import Core

struct RouteCodingTests {
    /// One sample of every route case, grouped as in `Route`. Add a line when a case is added.
    static let allRoutes: [Route] = [
        .onboarding(.nameAndPhoto), .onboarding(.interests), .onboarding(.location), .onboarding(.findFriends),
        .auth(.signIn), .auth(.emailSignIn), .auth(.accountBasics),
        .hangoutDetail(.detail("h1")), .hangoutDetail(.remixTree("h1")),
        .live(.summary("r1")),
        .posting(.compose("r1")),
        .search(.seeAll(.hangouts)), .search(.seeAll(.places)), .search(.seeAll(.people)),
        .profile(.person("u1")), .profile(.saved), .profile(.drafts), .profile(.mutualFriends("u1")),
        .profile(.readyToPost), .profile(.settings), .profile(.deleteAccount)
    ] + SettingsPage.allCases.map { Route.profile(.settingsPage($0)) } + [
        .community(.post("r1")), .community(.trending), .community(.activity),
        .friends(.hub),
        .chat(.list), .chat(.conversation("c1")), .chat(.groupInfo("c1")),
        .moderation(.report(.run("r1"))), .moderation(.report(.comment("c1"))), .moderation(.report(.user("u1"))),
        .moderation(.report(.message("m1"))), .moderation(.report(.place("p1")))
    ] + AdminPage.allCases.map { Route.moderation(.admin($0)) } + [
        .editor(.suggestPlace)
    ]

    static let allSheets: [Sheet] = [
        .spot("p1"), .report(.place("p1")), .share(.hangout("h1")), .share(.post("r1")), .suggestPlace,
        .editPost("r1"), .groupInvitation("c1")
    ]

    static let allCovers: [Cover] = [.live("h1"), .editor(.new), .editor(.draft("h1")), .editor(.remix("h1"))]

    @Test(arguments: allRoutes)
    func everyRouteRoundTripsThroughJSON(route: Route) throws {
        let data = try JSONCoding.encoder.encode(route)
        #expect(try JSONCoding.decoder.decode(Route.self, from: data) == route)
    }

    @Test(arguments: allSheets)
    func everySheetRoundTripsThroughJSON(sheet: Sheet) throws {
        let data = try JSONCoding.encoder.encode(sheet)
        #expect(try JSONCoding.decoder.decode(Sheet.self, from: data) == sheet)
    }

    @Test(arguments: allCovers)
    func everyCoverRoundTripsThroughJSON(cover: Cover) throws {
        let data = try JSONCoding.encoder.encode(cover)
        #expect(try JSONCoding.decoder.decode(Cover.self, from: data) == cover)
    }

    @Test func aRouteListRoundTrips() throws {
        let data = try JSONCoding.encoder.encode(Self.allRoutes)
        #expect(try JSONCoding.decoder.decode([Route].self, from: data) == Self.allRoutes)
    }

    @Test func routeSamplesAreAllDifferent() {
        #expect(Set(Self.allRoutes).count == Self.allRoutes.count)
    }

    @Test func aRouteThatNoLongerExistsFailsToDecodeInsteadOfCrashing() {
        let json = Data(#"{"hangoutDetail":{"hologram":{"_0":"h1"}}}"#.utf8)
        #expect(throws: DecodingError.self) { try JSONCoding.decoder.decode(Route.self, from: json) }
    }

    @Test func sheetAndCoverIDsAreStableAndDistinct() {
        #expect(Set(Self.allSheets.map(\.id)).count == 6)   // the two share cases share one id
        #expect(Cover.live("h1").id == "live-h1")
        #expect(Sheet.spot("p1").id == "spot-p1")
    }

    @Test func tabsAndStacksRoundTrip() throws {
        for tab in AppTab.allCases {
            #expect(try JSONCoding.decoder.decode(AppTab.self, from: JSONCoding.encoder.encode(tab)) == tab)
        }
        let stacks: [StackID] = [.onboarding, .tab(.search), .live, .editor, .sheet]
        for stack in stacks {
            #expect(try JSONCoding.decoder.decode(StackID.self, from: JSONCoding.encoder.encode(stack)) == stack)
        }
        #expect(AppTab.allCases.last == .search)
    }
}
