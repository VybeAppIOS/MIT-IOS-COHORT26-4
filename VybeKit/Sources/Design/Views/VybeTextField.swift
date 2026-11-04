import SwiftUI

/// A text field with an optional error message under it. The message has an icon and words,
/// so it is never colour alone, and VoiceOver reads it as its own line right after the field.
/// (A SwiftUI `TextFieldStyle` cannot draw text below the field, so this is a small view instead.)
public struct VybeTextField: View {
    private let title: VybeText
    @Binding private var text: String
    @FocusState private var isFocused: Bool
    private let errorText: String?

    public init(_ title: LocalizedStringResource, text: Binding<String>, errorText: String? = nil) {
        self.title = .fixed(title)
        self._text = text
        self.errorText = errorText
    }

    public init(verbatim title: String, text: Binding<String>, errorText: String? = nil) {
        self.title = .verbatim(title)
        self._text = text
        self.errorText = errorText
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
            TextField(text: $text) { title.text }
                .font(Theme.Font.body)
                .focused($isFocused)
                .padding(.horizontal, Theme.Spacing.medium)
                .frame(minHeight: Theme.Size.minTapTarget)
                .background(Theme.Color.surfaceRaised, in: .rect(cornerRadius: Theme.Radius.medium))
                .overlay {
                    if errorText != nil {
                        RoundedRectangle(cornerRadius: Theme.Radius.medium).stroke(Theme.Color.critical)
                    }
                }
                // The text field itself is shorter than 44 pt; tapping anywhere in the pill focuses it.
                .contentShape(.rect(cornerRadius: Theme.Radius.medium))
                .onTapGesture { isFocused = true }
            if let errorText {
                Label {
                    Text(verbatim: errorText)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                }
                .font(Theme.Font.footnote)
                .foregroundStyle(Theme.Color.critical)
            }
        }
    }
}

private struct TextFieldDemo: View {
    @State private var name = ""
    @State private var area = "Kothrud"
    @State private var tooLong = "Kothrud Hangout with chai, fort views and a very long name"

    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            VybeTextField(verbatim: "Hangout name", text: $name)
            VybeTextField(verbatim: "Area", text: $area)
            VybeTextField(verbatim: "Title", text: $tooLong, errorText: "Keep the title under 40 characters.")
        }
        .padding(Theme.Spacing.large)
        .background(Theme.Color.surface)
    }
}

#Preview("VybeTextField") {
    TextFieldDemo()
}

#Preview("VybeTextField, large text") {
    TextFieldDemo()
        .dynamicTypeSize(.accessibility3)
}
