import Components
import Design
import SwiftUI

/// The visited Spots as a step-by-step timeline: a numbered circle per Spot joined by one vertical line, with a
/// rounded thumbnail, the name, the category and the note. Shows the order only, never a time.
struct SpotTimeline: View {
    let rows: [SpotRowData]
    @ScaledMetric(relativeTo: .body) private var markerSize: CGFloat = 32
    @ScaledMetric(relativeTo: .body) private var thumbnailSize: CGFloat = 72
    @ScaledMetric(relativeTo: .body) private var lineWidth: CGFloat = 2

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                HStack(alignment: .top, spacing: Theme.Spacing.medium) {
                    marker(row, isLast: index == rows.count - 1)
                    details(row)
                        .padding(.bottom, index == rows.count - 1 ? 0 : Theme.Spacing.large)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    /// The numbered circle, with the line running from it down to the next circle.
    private func marker(_ row: SpotRowData, isLast: Bool) -> some View {
        VStack(spacing: Theme.Spacing.tiny) {
            Text(verbatim: row.order.formatted())
                .font(Theme.Font.subheadline.weight(.bold))
                .foregroundStyle(Theme.Color.onAccent)
                .frame(width: markerSize, height: markerSize)
                .background(Theme.Color.accent, in: .circle)
            if !isLast {
                Rectangle()
                    .fill(Theme.Color.separator)
                    .frame(width: lineWidth)
                    .frame(maxHeight: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    private func details(_ row: SpotRowData) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.medium) {
            PlaceImage(url: row.thumbnailURL, aspectRatio: 1)
                .frame(width: thumbnailSize, height: thumbnailSize)
                .background(Theme.Color.surfaceRaised)
                .clipShape(.rect(cornerRadius: Theme.Radius.medium))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.medium).stroke(Theme.Color.separator))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                Text(verbatim: row.placeName).font(Theme.Font.headline).foregroundStyle(Theme.Color.textPrimary)
                Text(verbatim: row.categoryText).font(Theme.Font.subheadline)
                    .foregroundStyle(Theme.Color.textSecondary)
                if let note = row.note {
                    Text(verbatim: note).font(Theme.Font.subheadline).foregroundStyle(Theme.Color.textPrimary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: spokenText(row)))
    }

    /// "Spot 2 of 3, EXAMPLE Park, Park or garden, EXAMPLE note"
    private func spokenText(_ row: SpotRowData) -> String {
        [ComponentStrings.spotPosition(row.order, of: row.total), row.placeName, row.categoryText, row.note]
            .compactMap(\.self).joined(separator: ", ")
    }
}

#if DEBUG
/// EXAMPLE values for previews only (ADR 004: samples never invent a real-looking venue).
private let sampleRows = [
    SpotRowData(id: "preview-1", order: 1, total: 3, placeName: "EXAMPLE Café", categoryText: "Café",
                note: "EXAMPLE note", state: .visited),
    SpotRowData(id: "preview-2", order: 2, total: 3, placeName: "EXAMPLE Park", categoryText: "Park or garden",
                note: "EXAMPLE note", state: .visited),
    SpotRowData(id: "preview-3", order: 3, total: 3, placeName: "EXAMPLE Fort", categoryText: "Fort",
                note: "EXAMPLE note", state: .visited)
]

#Preview("Timeline") {
    SpotTimeline(rows: sampleRows).padding(Theme.Spacing.large).background(Theme.Color.surface)
}

#Preview("Timeline, large text") {
    ScrollView { SpotTimeline(rows: sampleRows).padding(Theme.Spacing.large) }
        .dynamicTypeSize(.accessibility3)
}
#endif
