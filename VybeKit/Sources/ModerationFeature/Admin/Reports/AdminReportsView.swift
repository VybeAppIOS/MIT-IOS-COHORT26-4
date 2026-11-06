import Components
import Design
import SwiftUI

/// Layout only: the reports queue. Tap a report for its detail and actions.
struct AdminReportsView: View {
    @State private var viewModel: AdminReportsViewModel

    init(viewModel: AdminReportsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private func retry() { Task { await viewModel.reload() } }

    var body: some View {
        Group {
            if viewModel.isAllowed {
                queue
            } else {
                EmptyStateView(systemImage: "lock", message: viewModel.teamOnlyMessage)
            }
        }
        .background(Theme.Color.surface)
        .navigationTitle(Text(verbatim: viewModel.title))
        .sheet(item: $viewModel.selected) { row in
            NavigationStack { AdminReportDetail(row: row, viewModel: viewModel) }
        }
        .task { await viewModel.load() }
    }

    private var queue: some View {
        LoadStateView(viewModel.state, onRetry: retry) { rows in
            List(rows) { row in
                Button { viewModel.rowTapped(row) } label: { AdminReportLine(row: row) }
            }
            .listStyle(.insetGrouped)
        } placeholder: {
            List { AdminReportLine(row: .placeholder) }.redacted(reason: .placeholder)
        } empty: {
            EmptyStateView(systemImage: "checkmark.shield", message: viewModel.emptyMessage)
        }
        .refreshable { await viewModel.reload() }
    }
}

private struct AdminReportLine: View {
    let row: AdminReportRow

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
            HStack(spacing: Theme.Spacing.small) {
                if row.isUrgent {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.Color.critical)
                        .accessibilityHidden(true)
                }
                Text(verbatim: row.reasonText).font(Theme.Font.headline).foregroundStyle(Theme.Color.textPrimary)
                Spacer(minLength: Theme.Spacing.small)
                Text(verbatim: row.targetText).font(Theme.Font.footnote).foregroundStyle(Theme.Color.textSecondary)
            }
            Label(row.timeLeftText, systemImage: row.isOverdue ? "clock.badge.exclamationmark" : "clock")
                .font(Theme.Font.footnote)
                .foregroundStyle(row.isOverdue ? Theme.Color.critical : Theme.Color.textSecondary)
        }
        .frame(minHeight: Theme.Size.minTapTarget)
        .accessibilityElement(children: .combine)
    }
}

/// The detail sheet: what was reported, then Hide (confirmed), Dismiss and Ban the owner.
private struct AdminReportDetail: View {
    let row: AdminReportRow
    @Bindable var viewModel: AdminReportsViewModel

    var body: some View {
        List {
            Section {
                InfoRow(verbatim: String(localized: "admin.detail.reason", bundle: #bundle), value: row.reasonText)
                InfoRow(verbatim: String(localized: "admin.detail.target", bundle: #bundle), value: row.targetText)
                InfoRow(verbatim: String(localized: "admin.detail.time", bundle: #bundle), value: row.timeLeftText)
                if let detail = row.detail { Text(verbatim: detail).font(Theme.Font.body) }
            }
            Section {
                if row.isAutoHidden {
                    SafetyNote(String(localized: "admin.detail.autoHidden", bundle: #bundle), style: .info)
                }
                SafetyNote(String(localized: "admin.detail.anonymous", bundle: #bundle), style: .info)
                if viewModel.actionFailed { SafetyNote(viewModel.actionError, style: .warning) }
            }
            Section {
                Button(String(localized: "admin.action.hide", bundle: #bundle), role: .destructive) {
                    viewModel.hideTapped(row.id)
                }
                .frame(minHeight: Theme.Size.minTapTarget)
                Button(String(localized: "admin.action.dismiss", bundle: #bundle)) {
                    Task { await viewModel.dismissTapped(row.id) }
                }
                .frame(minHeight: Theme.Size.minTapTarget)
                if row.ownerID != nil {
                    Button(String(localized: "admin.action.ban", bundle: #bundle), role: .destructive) {
                        viewModel.banOwnerTapped()
                    }
                    .frame(minHeight: Theme.Size.minTapTarget)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Text(verbatim: row.reasonText))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(String(localized: "admin.action.hide.confirm", bundle: #bundle),
                            isPresented: $viewModel.isConfirmingHide, titleVisibility: .visible) {
            Button(String(localized: "admin.action.hide", bundle: #bundle), role: .destructive) {
                Task { await viewModel.hideConfirmed() }
            }
            Button(SharedStrings.cancel, role: .cancel) {}
        }
    }
}
