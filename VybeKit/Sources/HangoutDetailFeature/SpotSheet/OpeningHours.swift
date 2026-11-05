import Foundation
import Models

/// Whether a Place is open right now, worked out from its `OpeningPeriod`s in Pune time.
enum OpeningStatus: Equatable, Sendable {
    /// Open now; closes at this moment (may be after midnight).
    case openUntil(Date)
    /// Closed now; opens later today at this moment.
    case opensAt(Date)
    /// Has hours, but none left today.
    case closedToday
    /// The Place lists no hours at all.
    case notListed
}

/// The "open until" rules, kept apart from the ViewModel so they are easy to test.
///
/// A period's times are "HH:mm" in Pune time. A close time at or before the open time means it closes the next
/// day: 18:00–01:00 is open until 1 am, and a close of "00:00" means midnight. So just after midnight the previous
/// day's late period still counts.
enum OpeningHours {
    /// Pune's calendar: periods are written in Pune time, whatever time zone the phone is in.
    static let pune: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
        return calendar
    }()

    static func status(of periods: [OpeningPeriod], at now: Date, calendar: Calendar = pune) -> OpeningStatus {
        guard !periods.isEmpty else { return .notListed }
        let today = calendar.startOfDay(for: now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return .closedToday }

        let lateYesterday = windows(on: yesterday, periods: periods, calendar: calendar)
        let todays = windows(on: today, periods: periods, calendar: calendar)

        let openNow = (lateYesterday + todays).filter { $0.contains(now) }
        if let closes = openNow.map(\.upperBound).max() { return .openUntil(closes) }
        if let opens = todays.map(\.lowerBound).filter({ $0 > now }).min() { return .opensAt(opens) }
        return .closedToday
    }

    /// The open intervals that start on `day`, one per period for that weekday.
    private static func windows(on day: Date, periods: [OpeningPeriod], calendar: Calendar) -> [Range<Date>] {
        let weekday = calendar.component(.weekday, from: day)
        return periods.filter { $0.weekday == weekday }.compactMap { period in
            guard let open = minutes(period.open), let close = minutes(period.close),
                  let start = calendar.date(byAdding: .minute, value: open, to: day),
                  var end = calendar.date(byAdding: .minute, value: close, to: day) else { return nil }
            if end <= start, let nextDay = calendar.date(byAdding: .day, value: 1, to: end) {
                end = nextDay                       // closes after midnight
            }
            return start..<end
        }
    }

    /// "18:30" → 1110 minutes after midnight; nil when the text is not a valid time.
    private static func minutes(_ text: String) -> Int? {
        let parts = text.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]),
              (0...23).contains(hour), (0...59).contains(minute) else { return nil }
        return hour * 60 + minute
    }
}
