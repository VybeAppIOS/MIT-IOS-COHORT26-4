import SwiftUI

/// An inline search box for places where the system `.searchable` bar does not fit.
public struct SearchField: View {
    private let prompt: VybeText
    @Binding private var text: String
    @FocusState private var isFocused: Bool

    public init(_ prompt: LocalizedStringResource, text: Binding<String>) {
        self.prompt = .fixed(prompt)
        self._text = text
    }

    public init(verbatim prompt: String, text: Binding<String>) {
        self.prompt = .verbatim(prompt)
        self._text = text
    }

    public var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.Color.textSecondary)
                .accessibilityHidden(true)
            TextField(text: $text) { prompt.text }
                .font(Theme.Font.body)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)
            if !text.isEmpty {
                IconButton(
                    systemImage: "xmark.circle.fill",
                    verbatimLabel: String(localized: "Clear search", bundle: .module)
                ) { text = "" }
            }
        }
        .padding(.leading, Theme.Spacing.medium)
        .frame(minHeight: Theme.Size.minTapTarget)
        .background(Theme.Color.surfaceRaised, in: .capsule)
        // The text field itself is shorter than 44 pt; tapping anywhere in the capsule focuses it.
        .contentShape(.capsule)
        .onTapGesture { isFocused = true }
    }
}

private struct SearchFieldDemo: View {
    @State private var empty = ""
    @State private var filled = "chai near Karve Road"

    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            SearchField(verbatim: "Search Hangouts and places", text: $empty)
            SearchField(verbatim: "Search Hangouts and places", text: $filled)
        }
        .padding(Theme.Spacing.large)
        .background(Theme.Color.surface)
    }
}

#Preview("SearchField") {
    SearchFieldDemo()
}

#Preview("SearchField, large text") {
    SearchFieldDemo()
        .dynamicTypeSize(.accessibility3)
}
