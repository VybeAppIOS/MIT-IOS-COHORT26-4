import Components
import Design
import SwiftUI

/// One result line shared by Search and See all: a picture, the title and a quiet second line. The whole row is the
/// tap target (at least 44 pt tall).
struct SearchRowView: View {
    let row: SearchRowData
    let action: () -> Void

    @ScaledMetric private var symbolSize: CGFloat = 36

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.medium) {
                leading
                VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                    Text(verbatim: row.title)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text(verbatim: row.subtitle)
                        .font(Theme.Font.footnote)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                Spacer(minLength: Theme.Spacing.small)
            }
            .padding(.vertical, Theme.Spacing.tiny)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    /// "Sample Aarav" gives "SA".
    private static func initials(of name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }

    @ViewBuilder private var leading: some View {
        switch row.leading {
        case .none:
            EmptyView()
        case .symbol(let name):
            Image(systemName: name)
                .font(Theme.Font.subheadline)
                .foregroundStyle(Theme.Color.accent)
                .frame(width: symbolSize, height: symbolSize)
                .background(Theme.Color.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: Theme.Radius.small))
                .accessibilityHidden(true)
        case .person(let name):
            Text(verbatim: Self.initials(of: name))
                .font(Theme.Font.subheadline.weight(.semibold))
                .foregroundStyle(Theme.Color.accent)
                .frame(width: symbolSize, height: symbolSize)
                .background(Theme.Color.accent.opacity(0.12), in: Circle())
                .accessibilityHidden(true)
        }
    }
}
