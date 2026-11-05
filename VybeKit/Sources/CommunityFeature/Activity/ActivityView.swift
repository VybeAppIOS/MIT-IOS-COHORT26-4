import Components
import Design
import SwiftUI

/// Layout only: every value comes from `ActivityViewModel`, every tap goes to it.
struct ActivityView: View {
    @State private var viewModel: ActivityViewModel
    @ScaledMetric(relativeTo: .body) private var iconWidth = 28.0

    init(viewModel: ActivityViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(
            viewModel.state,
            onRetry: { Task { await viewModel.reload() } },
            content: { content in list(content) },
            placeholder: { ActivitySkeleton() },
            empty: { EmptyStateView(systemImage: "bell", message: viewModel.emptyMessage) })
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        .alert(
            Text(verbatim: viewModel.notice ?? ""),
            isPresented: Binding(get: { viewModel.notice != nil }, set: { if !$0 { viewModel.notice = nil } })
        ) {
            Button(role: .cancel) {} label: { Text(verbatim: viewModel.okLabel) }
        }
    }

    private func list(_ content: ActivityContent) -> some View {
        List {
            ForEach(content.sections) { section in
                Section {
                    ForEach(section.rows) { row in rowView(row) }
                } header: {
                    Text(verbatim: section.title)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func rowView(_ row: ActivityRowData) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Button { viewModel.rowTapped(row.id) } label: {
                HStack(alignment: .top, spacing: Theme.Spacing.medium) {
                    Image(systemName: row.systemImage)
                        .foregroundStyle(Theme.Color.accent)
                        .frame(width: iconWidth)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                        Text(verbatim: row.text)
                            .font(row.isUnread ? Theme.Font.body.weight(.semibold) : Theme.Font.body)
                            .foregroundStyle(Theme.Color.textPrimary)
                            .multilineTextAlignment(.leading)
                        Text(verbatim: row.relativeText)
                            .font(Theme.Font.footnote)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    Spacer(minLength: 0)
                    if row.isUnread {
                        Circle().fill(Theme.Color.accent).frame(width: Theme.Spacing.small, height: Theme.Spacing.small)
                            .accessibilityLabel(Text(verbatim: viewModel.unreadLabel))
                    }
                }
                .frame(minHeight: Theme.Size.minTapTarget)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            if row.phase == .waiting {
                HStack(spacing: Theme.Spacing.small) {
                    PillButton(verbatim: viewModel.acceptLabel, style: .prominent, fillsWidth: true) {
                        Task { await viewModel.acceptTapped(row.id) }
                    }
                    PillButton(verbatim: viewModel.ignoreLabel, fillsWidth: true) { viewModel.ignoreTapped(row.id) }
                }
            }
        }
        .accessibilityElement(children: row.phase == .waiting ? .contain : .combine)
    }
}

/// The loading look: a few grey rows.
private struct ActivitySkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            SkeletonLine(widthFraction: 0.3)
            SkeletonLine()
            SkeletonLine(widthFraction: 0.8)
            SkeletonLine(widthFraction: 0.6)
        }
        .padding(Theme.Spacing.large)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
