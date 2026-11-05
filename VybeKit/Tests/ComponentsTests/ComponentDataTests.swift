import CoreGraphics
import Design
import Foundation
import Models
import Testing
@testable import Components

/// The display values the components build (CP-1, CP-2, CP-4, CP-6, CP-8, CP-11): what people and VoiceOver read.
@MainActor
struct ComponentDataTests {
    // MARK: CP-1 HangoutCard

    @Test func aHangoutCardIsBuiltFromTheHangoutWithTheSharedFormatting() {
        let card = HangoutCardData(SampleData.evening, coverURL: nil, isSaved: true)
        #expect(card.spotCount == 2 && card.spotsText == "2 Spots")
        #expect(card.budgetText == "₹150–400")
        #expect(card.durationText == "about 2 h")
        #expect(card.factsText == "2 Spots · ₹150–400 · about 2 h")
        #expect(card.isPick && card.isSaved)
    }

    @Test func theCardIsReadAsOneSentence() {
        let card = HangoutCardData(SampleData.evening, coverURL: nil, isSaved: false)
        #expect(card.accessibilityText.hasPrefix("Hangout: Coffee, Then a Garden Walk, 2 Spots"))
        #expect(card.accessibilityText.hasSuffix("Picks"))
    }

    @Test func oneSpotIsSingular() {
        #expect(ComponentStrings.spotCount(1) == "1 Spot")
        #expect(ComponentStrings.spotCount(5) == "5 Spots")
    }

    // MARK: CP-2 SpotRow

    @Test func aSpotRowIsBuiltFromTheSpotAndItsPlace() {
        let spot = SampleData.evening.spots[0]
        let row = SpotRowData(spot: spot, place: SampleData.cafe, order: 1, total: 4, state: .visited)
        #expect(row.placeName == SampleData.cafe.name)
        #expect(row.categoryText == "Café")
        #expect(row.minutesText == "45 min")
        #expect(row.accessibilityText.hasPrefix("Spot 1 of 4, Amarii Cafe, Café · 45 min, Visited"))
    }

    @Test func aPlaceClosedByTheAuthoritiesAlwaysShowsAsClosed() {
        var place = SampleData.cafe
        place.status = .closedByAuthorities
        let row = SpotRowData(spot: SampleData.evening.spots[0], place: place, order: 1, total: 2, state: .current)
        #expect(row.state == .closedByAuthorities)
    }

    @Test func everyCategoryHasAName() {
        #expect(ComponentStrings.categoryName(.streetFood) == "Street food")
        #expect(ComponentStrings.categoryName(.unknown) == "Place")
        for category in PlaceCategory.allCases {
            #expect(!ComponentStrings.categoryName(category).hasPrefix("category."), "\(category) has no name")
        }
    }

    // MARK: CP-4 Avatar

    @Test(arguments: [("Aarav Kulkarni", "AK"), ("sample.me", "SM"), ("Vybe", "V"), ("", "?")])
    func initials(name: String, expected: String) {
        #expect(Avatar.initials(of: name) == expected)
    }

    // MARK: CP-6 PostCard

    @Test func aPostCardNeverShowsAClockTime() {
        let card = PostCardData.previewPick
        #expect(card.visitedSummary == "2 of 2 Spots")
        #expect(card.username.hasPrefix("@"))
        #expect(card.dayText != nil)
        #expect(card.dayText?.contains(":") == false)
    }

    @Test func theRouteDrawingFitsInsideItsMargin() {
        let size = CGSize(width: 200, height: 150)
        let one = RouteMiniMap.layout([SampleData.cafe.coordinate], in: size, inset: 20)
        #expect(one == [CGPoint(x: 100, y: 75)])
        let two = RouteMiniMap.layout(SampleData.places.map(\.coordinate), in: size, inset: 20)
        for point in two {
            #expect((20...180).contains(point.x) && (20...130).contains(point.y))
        }
        #expect(RouteMiniMap.layout([], in: size, inset: 20).isEmpty)
    }

    // MARK: CP-8 Messages

    @Test func pollCountsAndVoiceNoteLength() {
        let poll = PollData(question: "EXAMPLE", imInCount: 3, notForMeCount: 1, myVote: .imIn)
        #expect(poll.count(for: .imIn) == 3 && poll.count(for: .notForMe) == 1)
        #expect(VoiceNoteData.durationText(seconds: 72) == "1:12")
        #expect(PollBubble.title(.imIn) == "I'm in")
    }

    // MARK: CP-11 Map pins

    @Test func everyKnownCategoryHasAPinSymbol() {
        for category in PlaceCategory.allCases where category != .unknown {
            #expect(HangoutPin.symbols[category] != nil, "\(category) has no pin symbol")
        }
        #expect(HangoutPin.symbol(for: .unknown) == "mappin")
    }

    @Test func clusterLabelUsesPluralRules() {
        #expect(ComponentStrings.clusterLabel(1) == "1 Hangout here, double tap to zoom")
        #expect(ComponentStrings.clusterLabel(3) == "3 Hangouts here, double tap to zoom")
    }
}
