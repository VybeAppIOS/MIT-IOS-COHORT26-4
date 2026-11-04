import Design
import SwiftUI

/// A banner for safety information, such as a trek note or the monsoon notice.
/// The message is passed in: this view never decides what a safety note says or when it is shown.
public struct SafetyNote: View {
    public enum Style: Sendable {
        case info
        case warning
    }

    private let message: String
    private let style: Style

    public init(_ message: String, style: Style = .info) {
        self.message = message
        self.style = style
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.medium) {
            Image(systemName: style == .warning ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .foregroundStyle(style == .warning ? Theme.Color.warning : Theme.Color.accent)
                .accessibilityHidden(true)
            Text(verbatim: message)
                .font(Theme.Font.subheadline)
                .foregroundStyle(Theme.Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Color.surfaceRaised, in: .rect(cornerRadius: Theme.Radius.medium))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(style == .warning ? Theme.Color.warning : Theme.Color.separator)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenPrefix + message)
    }

    private var spokenPrefix: String {
        style == .warning ? String(localized: "Warning. ") : String(localized: "Note. ")
    }
}

// The text below is placeholder wording for previews only. Real safety text comes from the Place data
// and from wording the team approves (docs/RISKS.md).
private let previewShort = "Preview placeholder: short safety note."
private let previewLong = "Preview placeholder: a much longer safety note that wraps onto several lines "
    + "so the banner can be checked at large text sizes."

private struct SafetyNoteSample: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.medium) {
            SafetyNote(previewShort, style: .info)
            SafetyNote(previewShort, style: .warning)
            SafetyNote(previewLong, style: .warning)
        }
        .padding(Theme.Spacing.large)
        .background(Theme.Color.surface)
    }
}

#Preview("SafetyNote") {
    SafetyNoteSample()
}

#Preview("SafetyNote, large text") {
    SafetyNoteSample()
        .dynamicTypeSize(.accessibility3)
}
