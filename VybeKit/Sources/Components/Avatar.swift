import Design
import SwiftUI

/// A person's round profile photo, with their initials when there is no photo, and a ring for the official Vybe
/// account. VoiceOver reads "<name>'s profile photo" only when it is tappable (`isTappable`); otherwise the name is
/// already written next to it, so the photo is hidden.
public struct Avatar: View {
    public enum Size: Sendable, CaseIterable {
        case tiny, small, medium, large, extraLarge

        /// Points at the default text size; grows with Dynamic Type through `@ScaledMetric`.
        var points: CGFloat {
            switch self {
            case .tiny: 24
            case .small: 32
            case .medium: 44
            case .large: 64
            case .extraLarge: 96
            }
        }
    }

    private let url: URL?
    private let name: String
    private let size: Size
    private let isVerifiedVybe: Bool
    private let isTappable: Bool
    @ScaledMetric(relativeTo: .body) private var scale = 1.0

    public init(url: URL?, name: String, size: Size = .medium, isVerifiedVybe: Bool = false, isTappable: Bool = false) {
        self.url = url
        self.name = name
        self.size = size
        self.isVerifiedVybe = isVerifiedVybe
        self.isTappable = isTappable
    }

    public var body: some View {
        let diameter = size.points * scale
        photo
            .frame(width: diameter, height: diameter)
            .clipShape(.circle)
            .overlay {
                if isVerifiedVybe {
                    Circle().strokeBorder(Theme.Color.accent, lineWidth: max(2, diameter / 16))
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if isVerifiedVybe && size != .tiny {
                    Image(systemName: "checkmark.seal.fill")
                        .font(size == .extraLarge ? Theme.Font.title3 : Theme.Font.caption2)
                        .foregroundStyle(Theme.Color.accent)
                        .background(Theme.Color.surface, in: .circle)
                }
            }
            .modifier(AvatarAccessibility(label: accessibilityText))
    }

    @ViewBuilder private var photo: some View {
        if url == nil {
            ZStack {
                // A tinted circle, so initials still read as an avatar on white cards and rows.
                Circle().fill(Theme.Color.accent.opacity(0.12))
                Text(verbatim: Self.initials(of: name))
                    .font(size.points >= 64 ? Theme.Font.title2 : Theme.Font.caption)
                    .foregroundStyle(Theme.Color.accent)
                    .minimumScaleFactor(0.5)
            }
        } else {
            PlaceImage(url: url, aspectRatio: 1)
        }
    }

    private var accessibilityText: String? {
        guard isTappable else { return nil }
        let label = ComponentStrings.avatarLabel(name)
        return isVerifiedVybe ? "\(label), \(ComponentStrings.avatarVerified)" : label
    }

    /// "Aarav Kulkarni" → "AK", "sample.me" → "S", "" → "?".
    static func initials(of name: String) -> String {
        let words = name.split(whereSeparator: { $0 == " " || $0 == "." }).prefix(2)
        let letters = words.compactMap(\.first).map { String($0).uppercased() }.joined()
        return letters.isEmpty ? "?" : letters
    }
}

private struct AvatarAccessibility: ViewModifier {
    let label: String?

    func body(content: Content) -> some View {
        if let label {
            content.accessibilityElement(children: .ignore).accessibilityLabel(Text(verbatim: label))
        } else {
            content.accessibilityHidden(true)
        }
    }
}

/// One person in an `AvatarStack`.
public struct AvatarStackPerson: Hashable, Sendable, Identifiable {
    public let id: String
    public var name: String
    public var photoURL: URL?

    public init(id: String, name: String, photoURL: URL? = nil) {
        self.id = id
        self.name = name
        self.photoURL = photoURL
    }
}

/// Overlapping profile photos with "+3" for the rest (friends who did a Hangout, group chat members).
/// VoiceOver reads the names that are shown and "3 more".
public struct AvatarStack: View {
    private let people: [AvatarStackPerson]
    private let maxShown: Int
    private let size: Avatar.Size

    public init(_ people: [AvatarStackPerson], maxShown: Int = 3, size: Avatar.Size = .small) {
        self.people = people
        self.maxShown = max(1, maxShown)
        self.size = size
    }

    public var body: some View {
        HStack(spacing: -size.points / 4) {
            ForEach(shown) { person in
                Avatar(url: person.photoURL, name: person.name, size: size)
                    .overlay(Circle().stroke(Theme.Color.surface, lineWidth: 2))
            }
            if hiddenCount > 0 {
                Text(verbatim: "+\(hiddenCount.formatted())")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .padding(.leading, size.points / 4 + Theme.Spacing.tiny)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: accessibilityText))
    }

    private var shown: [AvatarStackPerson] { Array(people.prefix(maxShown)) }
    private var hiddenCount: Int { max(0, people.count - maxShown) }

    private var accessibilityText: String {
        var parts = shown.map(\.name)
        if hiddenCount > 0 { parts.append(ComponentStrings.avatarMore(hiddenCount)) }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Previews

#if DEBUG
private let samplePeople = ["Sample Aarav", "Sample Isha", "Sample Rohan", "Sample Meera", "Sample Kabir",
                            "Sample Sanya", "Sample Vihaan", "Sample Tara"]
    .enumerated().map { AvatarStackPerson(id: "p\($0.offset)", name: $0.element) }

#Preview("Sizes, initials, verified") {
    VStack(spacing: Theme.Spacing.large) {
        HStack(spacing: Theme.Spacing.medium) {
            ForEach(Avatar.Size.allCases, id: \.self) { size in
                Avatar(url: nil, name: "Sample Aarav", size: size)
            }
        }
        HStack(spacing: Theme.Spacing.medium) {
            Avatar(url: nil, name: "Vybe", size: .large, isVerifiedVybe: true, isTappable: true)
            Avatar(url: URL(filePath: "/EXAMPLE/missing.jpg"), name: "Sample Isha", size: .large)
        }
    }
    .padding(Theme.Spacing.large)
}

#Preview("Stacks of 1, 3 and 8") {
    VStack(alignment: .leading, spacing: Theme.Spacing.large) {
        AvatarStack(Array(samplePeople.prefix(1)))
        AvatarStack(Array(samplePeople.prefix(3)))
        AvatarStack(samplePeople)
    }
    .padding(Theme.Spacing.large)
}

#Preview("Large text") {
    AvatarStack(samplePeople, size: .medium)
        .padding(Theme.Spacing.large)
        .dynamicTypeSize(.accessibility3)
}
#endif
