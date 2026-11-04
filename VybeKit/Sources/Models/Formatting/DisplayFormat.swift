import Foundation

/// Display text for money, time, distance and counts, so every feature writes them the same way.
/// Everything goes through `.formatted(...)`; never type "Rs" or "km" by hand (`AGENTS.md` 5a).
/// The app is for Pune, so all of them use Indian conventions.
public enum DisplayFormat {
    public static let locale = Locale(identifier: "en_IN")

    /// "₹150–400"; "₹200" when both ends are equal.
    public static func rupeeRange(lower: Int, upper: Int) -> String {
        let currency = IntegerFormatStyle<Int>.Currency(code: "INR", locale: locale).precision(.fractionLength(0))
        let first = lower.formatted(currency)
        guard upper != lower else { return first }
        return "\(first)–\(upper.formatted(.number.locale(locale)))"
    }

    /// Rounded and prefixed with "about": 170 minutes is "about 3 h", 90 is "about 1.5 h", 42 is "about 40 min".
    public static func roundedDuration(minutes: Int) -> String {
        let rounded = max(5, Int((Double(minutes) / 5).rounded()) * 5)
        if rounded < 60 {
            let text = rounded.formatted(.number.locale(locale))
            return String(localized: "duration.aboutMinutes \(text)", bundle: #bundle)
        }
        let hours = (Double(minutes) / 30).rounded() / 2
        let text = hours.formatted(.number.precision(.fractionLength(0...1)).locale(locale))
        return String(localized: "duration.aboutHours \(text)", bundle: #bundle)
    }

    /// "2.4 km".
    public static func distance(meters: Double) -> String {
        Measurement(value: meters / 1000, unit: UnitLength.kilometers).formatted(
            .measurement(width: .abbreviated, usage: .asProvided,
                         numberFormatStyle: .number.precision(.fractionLength(0...1))).locale(locale))
    }

    /// "999", "1.2K".
    public static func compactCount(_ count: Int) -> String {
        count.formatted(.number.notation(.compactName).locale(locale))
    }
}
