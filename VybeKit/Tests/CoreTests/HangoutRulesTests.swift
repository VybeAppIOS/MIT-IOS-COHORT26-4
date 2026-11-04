import Foundation
import Models
import Testing
@testable import Core

struct HangoutRulesTests {
    private func spots(_ places: [String]) -> [Spot] {
        places.enumerated().map { Spot(id: SpotID("s\($0.offset)"), placeID: PlaceID($0.element)) }
    }

    private func places(_ count: Int) -> [PlaceID] { (1...count).map { PlaceID("p\($0)") } }

    // MARK: Spot count

    @Test(arguments: [(0, false), (1, false), (2, true), (5, true), (10, true), (11, false), (-1, false)])
    func spotCountBoundaries(count: Int, valid: Bool) {
        #expect(HangoutRules.isValidSpotCount(count) == valid)
    }

    // MARK: Duplicate place

    @Test func theSamePlaceTwiceIsFlagged() {
        #expect(HangoutRules.hasDuplicatePlace(spots(["a", "b", "a"])))
        #expect(!HangoutRules.hasDuplicatePlace(spots(["a", "b", "c"])))
        #expect(!HangoutRules.hasDuplicatePlace([]))
        #expect(!HangoutRules.hasDuplicatePlace(spots(["a"])))
    }

    // MARK: Remix (70%)

    @Test(arguments: [(10, 7, true), (10, 6, false), (10, 10, true), (10, 0, false), (3, 2, false), (3, 3, true),
                      (2, 2, true), (2, 1, false), (100, 70, true), (100, 69, false), (4, 3, true), (5, 4, true)])
    func remixKeepBoundaries(original: Int, kept: Int, enough: Bool) {
        let originalPlaces = places(original)
        let remix = Array(originalPlaces.prefix(kept)) + [PlaceID("new-1"), PlaceID("new-2")]
        #expect(HangoutRules.remixKeepsEnough(original: originalPlaces, remix: remix) == enough)
    }

    @Test func remixCountsPlacesNotSpots() {
        // A Place used twice in the original counts once; keeping it once keeps it.
        let original: [PlaceID] = ["a", "a", "b", "c"]
        #expect(HangoutRules.remixKeepsEnough(original: original, remix: ["a", "b", "x"]) == false)   // 2 of 3 = 66%
        #expect(HangoutRules.remixKeepsEnough(original: original, remix: ["a", "b", "c"]))
        #expect(HangoutRules.remixKeepsEnough(original: original, remix: ["a", "a", "b", "c", "d"]))
    }

    @Test func aRemixThatAddsPlacesStillNeedsTheOriginalOnes() {
        #expect(!HangoutRules.remixKeepsEnough(original: ["a", "b"], remix: ["x", "y", "z", "a"]))
        #expect(HangoutRules.remixKeepsEnough(original: ["a", "b"], remix: ["a", "b", "x", "y"]))
    }

    @Test func anOriginalWithoutPlacesCannotBeRemixed() {
        #expect(!HangoutRules.remixKeepsEnough(original: [], remix: ["a"]))
        #expect(!HangoutRules.remixKeepsEnough(original: [], remix: []))
    }

    // MARK: Posting

    @Test(arguments: [(0, false), (1, false), (2, true), (3, true), (10, true)])
    func canPostNeedsTwoVisitedSpots(visited: Int, allowed: Bool) {
        #expect(HangoutRules.canPost(visitedCount: visited) == allowed)
    }

    @Test(arguments: [(0, 0), (1, 2), (2, 4), (5, 10), (10, 20), (-3, 0)])
    func photosAreTwoPerVisitedSpot(visited: Int, expected: Int) {
        #expect(HangoutRules.maxPhotos(visitedCount: visited) == expected)
    }

    // MARK: Earliest post time

    private var india: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        return calendar
    }

    /// 2026-11-03 22:50 in India (17:20 UTC).
    private let endedAt = Date(timeIntervalSince1970: 1_793_726_400)

    @Test func thirtyMinutesIsTheDefaultAndTheMinimum() {
        let defaultTime = HangoutRules.earliestPostTime(endedAt: endedAt, calendar: india)
        #expect(defaultTime == endedAt.addingTimeInterval(30 * 60))
        #expect(HangoutRules.earliestPostTime(endedAt: endedAt, delay: .thirtyMinutes) == defaultTime)
    }

    @Test func twoHoursIsTwoHoursAfter() {
        #expect(HangoutRules.earliestPostTime(endedAt: endedAt, delay: .twoHours, calendar: india)
            == endedAt.addingTimeInterval(2 * 3600))
    }

    @Test func nextDayIsNineInTheMorningTheDayAfter() {
        let time = HangoutRules.earliestPostTime(endedAt: endedAt, delay: .nextDay, calendar: india)
        let parts = india.dateComponents([.year, .month, .day, .hour, .minute], from: time)
        #expect(parts.year == 2026 && parts.month == 11 && parts.day == 4)
        #expect(parts.hour == 9 && parts.minute == 0)
    }

    @Test func nextDayAfterMidnightStillMeansTheFollowingDay() {
        // 00:10 India on 2026-11-04 (18:40 UTC the day before): "tomorrow" is the 5th at 9:00.
        let afterMidnight = Date(timeIntervalSince1970: 1_793_731_800)
        let time = HangoutRules.earliestPostTime(endedAt: afterMidnight, delay: .nextDay, calendar: india)
        let parts = india.dateComponents([.month, .day, .hour], from: time)
        #expect(parts.month == 11 && parts.day == 5 && parts.hour == 9)
    }

    @Test func everyDelayIsAtLeastThirtyMinutesAfterTheEnd() {
        for delay in PostDelay.allCases {
            let time = HangoutRules.earliestPostTime(endedAt: endedAt, delay: delay, calendar: india)
            #expect(time.timeIntervalSince(endedAt) >= HangoutRules.minimumPostDelay)
        }
    }

    @Test func timeIsAlwaysAParameter() {
        // The same inputs always give the same answer: nothing reads the clock.
        let first = HangoutRules.earliestPostTime(endedAt: endedAt, delay: .nextDay, calendar: india)
        let second = HangoutRules.earliestPostTime(endedAt: endedAt, delay: .nextDay, calendar: india)
        #expect(first == second)
    }

    // MARK: Rounded duration

    @Test func roundedDurationUsesTheSharedWords() {
        #expect(HangoutRules.roundedDuration(170) == "about 3 h")
        #expect(HangoutRules.roundedDuration(40) == "about 40 min")
    }
}
