import Foundation
import Testing
@testable import Models

struct FormattingTests {
    @Test func rupeeRange() {
        #expect(RupeeRange(lower: 150, upper: 400).formattedPerPerson == "₹150–400")
        #expect(RupeeRange(lower: 200, upper: 200).formattedPerPerson == "₹200")
        #expect(RupeeRange(lower: 100_000, upper: 250_000).formattedPerPerson == "₹1,00,000–2,50,000")
    }

    @Test(arguments: [
        (170, "about 3 h"), (90, "about 1.5 h"), (60, "about 1 h"), (58, "about 1 h"), (55, "about 55 min"),
        (42, "about 40 min"), (10, "about 10 min"), (1, "about 5 min"), (0, "about 5 min")
    ])
    func roundedDuration(minutes: Int, expected: String) {
        #expect(DisplayFormat.roundedDuration(minutes: minutes) == expected)
    }

    @Test func distance() {
        #expect(DisplayFormat.distance(meters: 2400) == "2.4 km")
        #expect(DisplayFormat.distance(meters: 12_000) == "12 km")
    }

    @Test func compactCount() {
        #expect(DisplayFormat.compactCount(999) == "999")
        #expect(DisplayFormat.compactCount(1200) == "1.2K")
    }
}
