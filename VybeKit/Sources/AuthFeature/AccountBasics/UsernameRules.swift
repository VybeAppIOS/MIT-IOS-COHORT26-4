import Foundation

/// The rules for a username and for the age check, as pure functions (no clock inside; dates are parameters).
enum UsernameRules {
    static let length = 3...20
    /// Names nobody may take: our own name and a staff-sounding one (decided with the team; Lohitaksh may move or
    /// extend this list).
    static let reserved: Set<String> = ["vybe", "admin"]

    enum Problem: Equatable, Sendable {
        /// Not 3 to 20 characters.
        case length
        /// Something other than a–z, 0–9, `_` and `.`.
        case characters
        /// A reserved word.
        case reserved
    }

    /// What is wrong with a username, or nil when it follows the rules. Expects the lower-cased name.
    static func problem(with username: String) -> Problem? {
        guard length.contains(username.count) else { return .length }
        let allowed = username.unicodeScalars.allSatisfy {
            ("a"..."z").contains($0) || ("0"..."9").contains($0) || $0 == "_" || $0 == "."
        }
        guard allowed else { return .characters }
        return reserved.contains(username) ? .reserved : nil
    }
}

/// The age check. Only people 18 and over may use Vybe.
enum AgeRule {
    static let minimumAge = 18

    /// True from the start of the 18th birthday. Someone born on 29 February turns 18 on 1 March in a year
    /// without one (the calendar rolls the missing day forward).
    static func isAdult(bornOn birthDate: Date, today: Date, calendar: Calendar) -> Bool {
        let born = calendar.dateComponents([.year, .month, .day], from: birthDate)
        guard let year = born.year,
              let eighteenth = calendar.date(from: DateComponents(year: year + minimumAge, month: born.month,
                                                                  day: born.day)) else { return false }
        return calendar.startOfDay(for: today) >= calendar.startOfDay(for: eighteenth)
    }
}
