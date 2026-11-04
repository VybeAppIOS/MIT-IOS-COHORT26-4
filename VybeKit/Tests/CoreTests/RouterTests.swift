import Observation
import Synchronization
import Testing
@testable import Core

@MainActor
struct RouterTests {
    @Test func openPushesOnTheSelectedTabsStack() {
        let router = Router()
        router.open(.hangout("h1"))
        router.selectedTab = .profile
        router.open(.saved)
        #expect(router.path(for: .tab(.discover)) == [.hangout("h1")])
        #expect(router.path(for: .tab(.profile)) == [.saved])
        #expect(router.currentStack == .tab(.profile))
    }

    @Test func openWithACoverPushesOnTheCoversStack() {
        let router = Router()
        router.presentCover(.live("h1"))
        router.open(.liveSummary("r1"))
        #expect(router.path(for: .live) == [.liveSummary("r1")])
        #expect(router.path(for: .tab(.discover)).isEmpty)

        router.dismissCover()
        router.presentCover(.editor(.new))
        router.open(.suggestPlace)
        #expect(router.path(for: .editor) == [.suggestPlace])
    }

    /// Report pushed inside the Spot sheet lands on the sheet's stack and disappears with the sheet.
    @Test func openWithASheetPushesOnTheSheetStackWhichGoesWithTheSheet() {
        let router = Router()
        router.present(.spot("p1"))
        router.open(.report(.place("p1")))
        #expect(router.path(for: .sheet) == [.report(.place("p1"))])
        #expect(router.path(for: .tab(.discover)).isEmpty)

        router.dismissSheet()
        #expect(router.sheet == nil)
        #expect(router.path(for: .sheet).isEmpty)
        router.open(.saved)
        #expect(router.path(for: .tab(.discover)) == [.saved])
    }

    @Test func aSheetOverACoverUsesTheSheetStack() {
        let router = Router()
        router.presentCover(.live("h1"))
        router.present(.spot("p1"))
        router.open(.report(.place("p1")))
        #expect(router.currentStack == .sheet)
        #expect(router.path(for: .live).isEmpty)
        router.dismissSheet()
        #expect(router.currentStack == .live)
    }

    @Test func presentingANewSheetStartsItsStackEmpty() {
        let router = Router()
        router.present(.spot("p1"))
        router.open(.report(.place("p1")))
        router.present(.share(.hangout("h1")))
        #expect(router.sheet == .share(.hangout("h1")))
        #expect(router.path(for: .sheet).isEmpty)
    }

    /// The back swipe: the system hands the host a shorter path and the host writes it back.
    @Test func setPathShrinksAStack() {
        let router = Router()
        router.open(.hangout("h1"))
        router.open(.remixTree("h1"))
        router.setPath([.hangout("h1")], for: .tab(.discover))
        #expect(router.path(for: .tab(.discover)) == [.hangout("h1")])
        router.setPath([], for: .tab(.discover))
        #expect(router.path(for: .tab(.discover)).isEmpty)
    }

    @Test func popAndPopToRoot() {
        let router = Router()
        router.pop()
        #expect(router.path(for: .tab(.discover)).isEmpty)
        router.open(.hangout("h1"))
        router.open(.remixTree("h1"))
        router.pop()
        #expect(router.path(for: .tab(.discover)) == [.hangout("h1")])
        router.open(.remixTree("h1"))
        router.popToRoot()
        #expect(router.path(for: .tab(.discover)).isEmpty)
    }

    @Test func dismissCoverClearsThatStackOnly() {
        let router = Router()
        router.open(.saved)
        router.presentCover(.live("h1"))
        router.open(.liveSummary("r1"))
        router.present(.spot("p1"))
        router.dismissCover()
        #expect(router.cover == nil && router.sheet == nil)
        #expect(router.path(for: .live).isEmpty)
        #expect(router.path(for: .tab(.discover)) == [.saved])
    }

    @Test func showSelectsTheTabClosesCoverAndSheetAndLeavesOneRoute() {
        let router = Router()
        router.presentCover(.live("h1"))
        router.open(.liveSummary("r1"))
        router.present(.spot("p1"))
        router.open(.report(.place("p1")))
        router.show(.hangout("h2"), in: .profile)
        #expect(router.selectedTab == .profile)
        #expect(router.cover == nil && router.sheet == nil)
        #expect(router.path(for: .tab(.profile)) == [.hangout("h2")])
        #expect(router.path(for: .live).isEmpty && router.path(for: .sheet).isEmpty)
    }

    @Test func showWithoutARouteLeavesTheTabAtItsRoot() {
        let router = Router()
        router.selectedTab = .community
        router.open(.trending)
        router.show(nil, in: .discover)
        #expect(router.selectedTab == .discover)
        #expect(router.path(for: .tab(.discover)).isEmpty)
    }

    @Test func resetClearsEverything() {
        let router = Router()
        router.setOnboarding(true)
        router.show(.saved, in: .profile)
        router.presentCover(.editor(.new))
        router.present(.suggestPlace)
        router.reset()
        #expect(router.paths.isEmpty)
        #expect(router.cover == nil && router.sheet == nil && !router.isOnboarding)
        #expect(router.selectedTab == .discover)
    }

    /// Also proves that `didSet` on an `@Observable` property fires (ADR 003).
    @Test func lastNonSearchTabIgnoresSearch() {
        let router = Router()
        #expect(router.lastNonSearchTab == .discover)
        router.selectedTab = .community
        #expect(router.lastNonSearchTab == .community)
        router.selectedTab = .search
        #expect(router.selectedTab == .search)
        #expect(router.lastNonSearchTab == .community)
        router.selectedTab = .profile
        #expect(router.lastNonSearchTab == .profile)
    }

    @Test func onboardingPushesOnItsOwnStack() {
        let router = Router()
        router.setOnboarding(true)
        router.open(.nameAndPhoto)
        router.open(.interests)
        #expect(router.currentStack == .onboarding)
        #expect(router.path(for: .onboarding) == [.nameAndPhoto, .interests])
        #expect(router.path(for: .tab(.discover)).isEmpty)

        router.setOnboarding(false)
        router.open(.saved)
        #expect(router.path(for: .tab(.discover)) == [.saved])
    }

    @Test func startingOnboardingAgainBeginsEmpty() {
        let router = Router()
        router.setOnboarding(true)
        router.open(.nameAndPhoto)
        router.setOnboarding(true)
        #expect(router.path(for: .onboarding).isEmpty)
    }

    @Test func changesAreObservable() {
        let router = Router()
        let changed = Mutex(false)
        withObservationTracking { _ = router.paths } onChange: { changed.withLock { $0 = true } }
        router.open(.saved)
        #expect(changed.withLock { $0 })
    }
}
