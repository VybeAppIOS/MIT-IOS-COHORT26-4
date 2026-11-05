import Foundation
import Models
import Testing
@testable import HangoutDetailFeature

/// The "open until" rules (task SC-HD2): midnight, days with no hours, and the ordinary cases.
/// Dates are in Pune time. 6 Nov 2026 is a Friday (weekday 6); 7 Nov is a Saturday (weekday 7).
/// `@MainActor` like the feature itself (features are main-actor by default, ADR 001).
@MainActor
struct OpeningHoursTests {
    private let friday = 6
    private let monday = 2

    private func pune(day: Int, _ hour: Int, _ minute: Int = 0) throws -> Date {
        try #require(OpeningHours.pune.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour,
                                                                  minute: minute)))
    }

    private func status(_ periods: [OpeningPeriod], at date: Date) -> OpeningStatus {
        OpeningHours.status(of: periods, at: date)
    }

    // MARK: Midnight

    @Test func aLatePeriodIsStillOpenJustAfterMidnight() throws {
        let lateFriday = [OpeningPeriod(weekday: friday, open: "18:00", close: "01:00")]
        #expect(status(lateFriday, at: try pune(day: 7, 0, 30)) == .openUntil(try pune(day: 7, 1)))
    }

    @Test func aLatePeriodIsOpenBeforeMidnightUntilTheNextDay() throws {
        let lateFriday = [OpeningPeriod(weekday: friday, open: "18:00", close: "01:00")]
        #expect(status(lateFriday, at: try pune(day: 6, 23)) == .openUntil(try pune(day: 7, 1)))
    }

    @Test func closingAtMidnightMeansTheEndOfTheDay() throws {
        let fridayHours = [OpeningPeriod(weekday: friday, open: "09:00", close: "00:00")]
        #expect(status(fridayHours, at: try pune(day: 6, 23, 30)) == .openUntil(try pune(day: 7, 0)))
    }

    @Test func atMidnightExactlyAMidnightCloseHasClosed() throws {
        let fridayHours = [OpeningPeriod(weekday: friday, open: "09:00", close: "00:00")]
        #expect(status(fridayHours, at: try pune(day: 7, 0)) == .closedToday)
    }

    // MARK: Days with no hours

    @Test func aDayWithNoHoursIsClosedToday() throws {
        let mondayOnly = [OpeningPeriod(weekday: monday, open: "09:00", close: "22:00")]
        #expect(status(mondayOnly, at: try pune(day: 6, 12)) == .closedToday)
    }

    @Test func noHoursAtAllIsNotListed() throws {
        #expect(status([], at: try pune(day: 6, 12)) == .notListed)
    }

    // MARK: Ordinary days

    @Test func beforeOpeningSaysWhenItOpens() throws {
        let day = [OpeningPeriod(weekday: friday, open: "09:00", close: "22:00")]
        #expect(status(day, at: try pune(day: 6, 7)) == .opensAt(try pune(day: 6, 9)))
    }

    @Test func afterClosingIsClosedToday() throws {
        let day = [OpeningPeriod(weekday: friday, open: "09:00", close: "22:00")]
        #expect(status(day, at: try pune(day: 6, 22)) == .closedToday)
    }

    @Test func twoPeriodsInOneDay() throws {
        let split = [OpeningPeriod(weekday: friday, open: "08:00", close: "11:00"),
                     OpeningPeriod(weekday: friday, open: "17:00", close: "22:00")]
        #expect(status(split, at: try pune(day: 6, 9)) == .openUntil(try pune(day: 6, 11)))
        #expect(status(split, at: try pune(day: 6, 13)) == .opensAt(try pune(day: 6, 17)))
    }

    @Test func anUnreadableTimeIsIgnored() throws {
        let broken = [OpeningPeriod(weekday: friday, open: "9am", close: "22:00")]
        #expect(status(broken, at: try pune(day: 6, 12)) == .closedToday)
    }
}
