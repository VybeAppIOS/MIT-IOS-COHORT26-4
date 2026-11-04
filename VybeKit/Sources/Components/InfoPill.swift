import Design
import SwiftUI

/// A small rounded label with an icon, for facts such as budget, time or number of Spots.
/// The text is final display text (built by a ViewModel with the formatting helpers), shown as given.
public struct InfoPill: View {
    private let icon: String
    private let text: String

    public init(icon: String, text: String) {
        self.icon = icon
        self.text = text
    }

    public var body: some View {
        HStack(spacing: Theme.Spacing.tiny) {
            Image(systemName: icon)
                .foregroundStyle(Theme.Color.accent)
                .accessibilityHidden(true)
            Text(verbatim: text)
                .foregroundStyle(Theme.Color.textPrimary)
        }
        .font(Theme.Font.footnote)
        .padding(.horizontal, Theme.Spacing.small)
        .padding(.vertical, Theme.Spacing.tiny)
        // A rounded rectangle, not a capsule: the text can wrap onto several lines at large text sizes.
        .background(Theme.Color.surfaceRaised, in: .rect(cornerRadius: Theme.Radius.medium))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.medium).stroke(Theme.Color.separator))
        .accessibilityElement(children: .combine)
    }
}

/// The best time of day for a Hangout, for example "Evening". The ViewModel supplies the words.
public struct BestTimeLabel: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        InfoPill(icon: "clock", text: text)
    }
}

// MARK: - Previews

private struct InfoPillSample: View {
    var body: some View {
        FlowLayout(spacing: Theme.Spacing.small, lineSpacing: Theme.Spacing.small) {
            InfoPill(icon: "indianrupeesign", text: "₹150–400")
            InfoPill(icon: "clock", text: "about 3 h")
            InfoPill(icon: "mappin.and.ellipse", text: "3 Spots")
            BestTimeLabel("Evening")
            InfoPill(icon: "figure.walk", text: "A long fact about walking from Karve Road to Paud Road and back")
        }
        .padding(Theme.Spacing.large)
        .background(Theme.Color.surface)
    }
}

#Preview("InfoPill") {
    InfoPillSample()
}

#Preview("InfoPill, large text") {
    InfoPillSample()
        .dynamicTypeSize(.accessibility3)
}
