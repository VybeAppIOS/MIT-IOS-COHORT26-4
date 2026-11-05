import Components
import Design
import SwiftUI

/// Layout only: a sheet with category chips, the Places, and "Can't find it?" at the bottom.
struct AddSpotView: View {
    @State private var viewModel: AddSpotViewModel
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric private var thumbnailSize: CGFloat = 52

    init(viewModel: AddSpotViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private func retry() { Task { await viewModel.reload() } }

    var body: some View {
        NavigationStack {
            LoadStateView(viewModel.state, onRetry: retry) { _ in
                List {
                    Section {
                        chipRow
                    }
                    Section {
                        if viewModel.visibleRows.isEmpty {
                            Text(verbatim: viewModel.filteredEmpty)
                                .font(Theme.Font.footnote)
                                .foregroundStyle(Theme.Color.textSecondary)
                        }
                        ForEach(viewModel.visibleRows) { row in placeRow(row) }
                    }
                }
                .listStyle(.insetGrouped)
            } placeholder: {
                List(0..<4, id: \.self) { _ in Text(verbatim: viewModel.title).frame(minHeight: thumbnailSize) }
            } empty: {
                EmptyStateView(systemImage: "mappin.slash", message: viewModel.emptyMessage,
                               actionTitle: viewModel.suggestTitle) { viewModel.suggestTapped() }
            }
            .navigationTitle(Text(verbatim: viewModel.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(SharedStrings.cancel) { dismiss() } }
            }
            .safeAreaInset(edge: .bottom) {
                SecondaryButton(verbatim: viewModel.suggestTitle) { viewModel.suggestTapped() }
                    .padding(.horizontal, Theme.Spacing.large)
                    .padding(.vertical, Theme.Spacing.medium)
                    .background(.bar)
            }
            .task { await viewModel.load() }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var chipRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Theme.Spacing.small) {
                ForEach(viewModel.chips) { chip in
                    FilterChip(verbatim: chip.title, isSelected: viewModel.isSelected(chip)) { viewModel.select(chip) }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func placeRow(_ row: AddSpotRow) -> some View {
        Button {
            viewModel.add(row.place)
            dismiss()
        } label: {
            HStack(spacing: Theme.Spacing.medium) {
                PlaceImage(url: row.thumbnailURL, aspectRatio: 1)
                    .frame(width: thumbnailSize)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                    Text(verbatim: row.place.name).font(Theme.Font.headline).foregroundStyle(Theme.Color.textPrimary)
                    Text(verbatim: row.categoryText)
                        .font(Theme.Font.subheadline)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                Spacer(minLength: Theme.Spacing.small)
                Image(systemName: "plus.circle.fill").foregroundStyle(Theme.Color.accent).accessibilityHidden(true)
            }
            .frame(minHeight: Theme.Size.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}
