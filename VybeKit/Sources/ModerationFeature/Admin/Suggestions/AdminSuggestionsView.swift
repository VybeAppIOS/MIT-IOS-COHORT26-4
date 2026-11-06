import Components
import Design
import SwiftUI

/// Layout only: pending suggestions; tap one to review it (approve into a Place, or reject).
struct AdminSuggestionsView: View {
    @State private var viewModel: AdminSuggestionsViewModel

    init(viewModel: AdminSuggestionsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private func retry() { Task { await viewModel.reload() } }

    var body: some View {
        Group {
            if viewModel.isAllowed {
                list
            } else {
                EmptyStateView(systemImage: "lock", message: viewModel.teamOnlyMessage)
            }
        }
        .background(Theme.Color.surface)
        .navigationTitle(Text(verbatim: viewModel.title))
        .sheet(isPresented: $viewModel.isReviewing) {
            NavigationStack { AdminReviewForm(viewModel: viewModel) }
        }
        .task { await viewModel.load() }
    }

    private var list: some View {
        LoadStateView(viewModel.state, onRetry: retry) { rows in
            List(rows) { row in
                Button { viewModel.rowTapped(row) } label: {
                    VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                        Text(verbatim: row.name).font(Theme.Font.headline).foregroundStyle(Theme.Color.textPrimary)
                        Text(verbatim: row.detailText)
                            .font(Theme.Font.footnote)
                            .foregroundStyle(Theme.Color.textSecondary)
                        if let note = row.note {
                            Text(verbatim: note).font(Theme.Font.body).foregroundStyle(Theme.Color.textSecondary)
                        }
                    }
                    .frame(minHeight: Theme.Size.minTapTarget)
                }
            }
            .listStyle(.insetGrouped)
        } placeholder: {
            List { Text(verbatim: viewModel.title) }.redacted(reason: .placeholder)
        } empty: {
            EmptyStateView(systemImage: "mappin.and.ellipse", message: viewModel.emptyMessage)
        }
        .refreshable { await viewModel.reload() }
    }
}

/// The review sheet: the Place's details (all editable), Approve; a note and Reject; one-tap Residential address.
private struct AdminReviewForm: View {
    @Bindable var viewModel: AdminSuggestionsViewModel

    var body: some View {
        Form {
            Section(String(localized: "admin.review.place", bundle: #bundle)) {
                VybeTextField(verbatim: String(localized: "admin.review.name", bundle: #bundle),
                              text: $viewModel.draft.name, errorText: nil)
                Picker(String(localized: "admin.review.category", bundle: #bundle),
                       selection: $viewModel.draft.category) {
                    ForEach(viewModel.categories) { Text(verbatim: $0.title).tag($0.category) }
                }
                VybeTextField(verbatim: String(localized: "admin.review.area", bundle: #bundle),
                              text: $viewModel.draft.area, errorText: nil)
                VybeTextField(verbatim: String(localized: "admin.review.address", bundle: #bundle),
                              text: $viewModel.draft.address, errorText: nil)
                TextField(String(localized: "admin.review.costLower", bundle: #bundle),
                          value: $viewModel.draft.costLower, format: .number)
                    .keyboardType(.numberPad)
                TextField(String(localized: "admin.review.costUpper", bundle: #bundle),
                          value: $viewModel.draft.costUpper, format: .number)
                    .keyboardType(.numberPad)
                Button(String(localized: "admin.review.approve", bundle: #bundle)) {
                    Task { await viewModel.approveTapped() }
                }
                .disabled(!viewModel.canApprove)
                .frame(minHeight: Theme.Size.minTapTarget)
            }
            Section(String(localized: "admin.review.reject.section", bundle: #bundle)) {
                Button(String(localized: "admin.review.residential", bundle: #bundle), role: .destructive) {
                    Task { await viewModel.rejectResidentialTapped() }
                }
                .frame(minHeight: Theme.Size.minTapTarget)
                VybeTextField(verbatim: String(localized: "admin.review.note", bundle: #bundle),
                              text: $viewModel.draft.rejectNote, errorText: nil)
                Button(String(localized: "admin.review.reject", bundle: #bundle), role: .destructive) {
                    Task { await viewModel.rejectTapped() }
                }
                .disabled(!viewModel.canReject)
                .frame(minHeight: Theme.Size.minTapTarget)
            }
            if viewModel.actionFailed {
                Section { SafetyNote(viewModel.actionError, style: .warning) }
            }
        }
        .navigationTitle(Text("admin.review.title", bundle: #bundle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(SharedStrings.cancel) { viewModel.closeReviewTapped() }
            }
        }
    }
}
