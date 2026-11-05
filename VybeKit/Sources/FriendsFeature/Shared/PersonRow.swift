import Components
import Design
import Foundation
import Models
import SwiftUI

/// One person in a list: a name, their username and an optional line such as "3 mutual friends".
struct PersonRowData: Identifiable, Equatable {
    let id: UserID
    let name: String
    let username: String
    let subtitle: String?

    init(_ profile: UserProfile, subtitle: String? = nil) {
        self.id = profile.id
        self.name = profile.displayName
        self.username = "@\(profile.username)"
        self.subtitle = subtitle
    }
}

/// A person row: the whole row opens the person; `trailing` holds buttons that must stay separate taps.
struct PersonRow<Trailing: View>: View {
    let person: PersonRowData
    let open: () -> Void
    private let trailing: Trailing

    init(person: PersonRowData, open: @escaping () -> Void, @ViewBuilder trailing: () -> Trailing) {
        self.person = person
        self.open = open
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            Button(action: open) {
                HStack(spacing: Theme.Spacing.medium) {
                    Avatar(url: nil, name: person.name, size: .medium)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(verbatim: person.name).font(Theme.Font.body).foregroundStyle(Theme.Color.textPrimary)
                        Text(verbatim: person.subtitle ?? person.username)
                            .font(Theme.Font.footnote)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    Spacer(minLength: 0)
                }
                .frame(minHeight: Theme.Size.minTapTarget)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            trailing
        }
    }
}

/// The loading look: a few grey rows. Shared by the people lists in this feature.
struct PersonListSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            SkeletonLine(widthFraction: 0.6)
            SkeletonLine(widthFraction: 0.8)
            SkeletonLine(widthFraction: 0.5)
            SkeletonLine(widthFraction: 0.7)
        }
        .padding(Theme.Spacing.large)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
