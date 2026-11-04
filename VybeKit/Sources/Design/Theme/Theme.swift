import SwiftUI

/// The only place colours, fonts, spacing, radii and animation values come from.
/// The tokens are in `Colors.swift`, `Typography.swift`, `Spacing.swift` and `Motion.swift`.
public enum Theme {}

// MARK: - Gallery (previews only)

private struct ThemeGallery: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var moved = false

    private let colors: [(name: String, color: SwiftUI.Color)] = [
        ("Surface", Theme.Color.surface),
        ("SurfaceRaised", Theme.Color.surfaceRaised),
        ("TextPrimary", Theme.Color.textPrimary),
        ("TextSecondary", Theme.Color.textSecondary),
        ("Accent", Theme.Color.accent),
        ("OnAccent", Theme.Color.onAccent),
        ("Positive", Theme.Color.positive),
        ("Warning", Theme.Color.warning),
        ("Critical", Theme.Color.critical),
        ("Separator", Theme.Color.separator),
        ("Scrim", Theme.Color.scrim)
    ]
    private let fonts: [(name: String, font: SwiftUI.Font)] = [
        ("largeTitle", Theme.Font.largeTitle),
        ("title", Theme.Font.title),
        ("title2", Theme.Font.title2),
        ("title3", Theme.Font.title3),
        ("headline", Theme.Font.headline),
        ("subheadline", Theme.Font.subheadline),
        ("body", Theme.Font.body),
        ("callout", Theme.Font.callout),
        ("footnote", Theme.Font.footnote),
        ("caption", Theme.Font.caption),
        ("caption2", Theme.Font.caption2)
    ]
    private let spacings: [(name: String, value: CGFloat)] = [
        ("tiny", Theme.Spacing.tiny), ("small", Theme.Spacing.small), ("medium", Theme.Spacing.medium),
        ("large", Theme.Spacing.large), ("extraLarge", Theme.Spacing.extraLarge), ("huge", Theme.Spacing.huge)
    ]
    private let radii: [(name: String, value: CGFloat)] = [
        ("small", Theme.Radius.small), ("medium", Theme.Radius.medium), ("large", Theme.Radius.large)
    ]
    private let motions: [(name: String, animation: Animation)] = [
        ("quick", Theme.Motion.quick), ("standard", Theme.Motion.standard), ("gentle", Theme.Motion.gentle),
        ("playful", Theme.Motion.playful), ("fade", Theme.Motion.fade)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
                section("Colour") {
                    ForEach(colors, id: \.name) { item in
                        HStack(spacing: Theme.Spacing.medium) {
                            RoundedRectangle(cornerRadius: Theme.Radius.small)
                                .fill(item.color)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.Radius.small)
                                        .stroke(Theme.Color.separator)
                                )
                                .frame(width: 56, height: 32)
                                .accessibilityHidden(true)
                            Text(verbatim: item.name).font(Theme.Font.body)
                        }
                    }
                }
                section("Type") {
                    ForEach(fonts, id: \.name) { item in
                        Text(verbatim: "\(item.name): Kothrud")
                            .font(item.font)
                    }
                }
                section("Spacing") {
                    ForEach(spacings, id: \.name) { item in
                        HStack(spacing: Theme.Spacing.medium) {
                            Text(verbatim: "\(item.name) \(Int(item.value))")
                                .font(Theme.Font.footnote)
                                .frame(minWidth: 64, alignment: .leading)
                            Rectangle().fill(Theme.Color.accent)
                                .frame(width: item.value, height: Theme.Spacing.medium)
                                .accessibilityHidden(true)
                        }
                    }
                }
                section("Radius") {
                    HStack(spacing: Theme.Spacing.large) {
                        ForEach(radii, id: \.name) { item in
                            VStack(spacing: Theme.Spacing.tiny) {
                                RoundedRectangle(cornerRadius: item.value)
                                    .fill(Theme.Color.accent)
                                    .frame(width: 64, height: 64)
                                    .accessibilityHidden(true)
                                Text(verbatim: "\(item.name) \(Int(item.value))")
                                    .font(Theme.Font.caption)
                            }
                        }
                    }
                }
                section("Size") {
                    Text(verbatim: "minTapTarget \(Int(Theme.Size.minTapTarget))")
                        .font(Theme.Font.footnote)
                        .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
                        .background(Theme.Color.surfaceRaised, in: .rect(cornerRadius: Theme.Radius.small))
                    Text(verbatim: readableWidthText)
                        .font(Theme.Font.footnote)
                }
                section("Motion (tap Move)") {
                    Button {
                        moved.toggle()
                    } label: {
                        Text(verbatim: "Move")
                            .font(Theme.Font.headline)
                            .foregroundStyle(Theme.Color.onAccent)
                            .frame(minWidth: 44, minHeight: 44)
                            .padding(.horizontal, Theme.Spacing.large)
                            .background(Theme.Color.accent, in: .rect(cornerRadius: Theme.Radius.medium))
                    }
                    ForEach(motions, id: \.name) { item in
                        HStack {
                            Text(verbatim: item.name)
                                .font(Theme.Font.footnote)
                                .frame(minWidth: 72, alignment: .leading)
                            Circle().fill(Theme.Color.accent)
                                .frame(width: Theme.Spacing.extraLarge, height: Theme.Spacing.extraLarge)
                                .offset(x: moved ? 160 : 0)
                                .animation(
                                    Theme.Motion.resolve(item.animation, reduceMotion: reduceMotion),
                                    value: moved
                                )
                                .accessibilityHidden(true)
                        }
                    }
                }
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Theme.Color.textPrimary)
        .background(Theme.Color.surface)
    }

    private var readableWidthText: String {
        let value = Theme.Size.readableContentMaxWidth.map { "\(Int($0))" } ?? "not decided"
        return "readableContentMaxWidth: \(value)"
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(verbatim: title)
                .font(Theme.Font.title3)
                .foregroundStyle(Theme.Color.textSecondary)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }
}

#Preview("ThemeGallery") {
    ThemeGallery()
}

#Preview("ThemeGallery, large text") {
    ThemeGallery()
        .dynamicTypeSize(.accessibility3)
}
