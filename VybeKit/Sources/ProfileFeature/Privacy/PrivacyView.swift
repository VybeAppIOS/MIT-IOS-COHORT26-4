import Components
import Design
import Models
import SwiftUI

/// Layout only: every value comes from `PrivacyViewModel`, every change goes to it and is saved at once.
struct PrivacyView: View {
    @State private var viewModel: PrivacyViewModel

    init(viewModel: PrivacyViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private func retry() { Task { await viewModel.reload() } }

    var body: some View {
        LoadStateView(viewModel.state, onRetry: retry) { content in
            form(content.profile)
        } placeholder: {
            List { Text(verbatim: viewModel.title) }.redacted(reason: .placeholder)
        } empty: {
            EmptyView()
        }
        .background(Theme.Color.surface)
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .hidesTabBar()
    }

    private func form(_ profile: UserProfile) -> some View {
        List {
            if viewModel.isOffline { Section { SafetyNote(viewModel.offlineText, style: .info) } }
            Section {
                ToggleRow(verbatim: viewModel.privateTitle, subtitle: viewModel.privateHint, isOn: toggle(
                    profile.isPrivate) { await viewModel.setPrivate($0) })
                ToggleRow(verbatim: viewModel.searchTitle, subtitle: viewModel.searchHint, isOn: toggle(
                    profile.settings.showMeInSearch) { await viewModel.setShowInSearch($0) })
            }
            Section {
                menu(viewModel.audienceTitle, profile.settings.defaultAudience, viewModel.audienceChoices,
                     enabled: viewModel.canChangeAudience) { await viewModel.setAudience($0) }
                menu(viewModel.commentTitle, profile.settings.whoCanComment, viewModel.commentChoices,
                     enabled: viewModel.canChange) { await viewModel.setComment($0) }
                menu(viewModel.requestsTitle, profile.settings.whoCanSendRequests, viewModel.requestChoices,
                     enabled: viewModel.canChange) { await viewModel.setRequests($0) }
                menu(viewModel.groupsTitle, profile.settings.whoCanAddMeToGroups, viewModel.groupChoices,
                     enabled: viewModel.canChange) { await viewModel.setGroups($0) }
            } footer: {
                if viewModel.isPrivate { Text(verbatim: viewModel.privateAudienceNote) }
            }
            if viewModel.showsPublicWarning {
                Section { SafetyNote(viewModel.publicWarning, style: .warning) }
            }
            if viewModel.saveFailed {
                Section { SafetyNote(viewModel.errorText, style: .warning) }
            }
        }
        .listStyle(.insetGrouped)
    }

    /// A switch that saves when flipped.
    private func toggle(_ value: Bool, save: @escaping (Bool) async -> Void) -> Binding<Bool> {
        Binding(get: { value }, set: { newValue in Task { await save(newValue) } })
    }

    /// A row with a menu of choices on the right (a standard Picker).
    private func menu<Value: Hashable & Sendable>(
        _ title: String, _ value: Value, _ choices: [PrivacyChoice<Value>], enabled: Bool,
        save: @escaping (Value) async -> Void
    ) -> some View {
        Picker(selection: Binding(get: { value }, set: { newValue in Task { await save(newValue) } })) {
            ForEach(choices) { choice in Text(verbatim: choice.title).tag(choice.value) }
        } label: {
            Text(verbatim: title)
        }
        .pickerStyle(.menu)
        .frame(minHeight: Theme.Size.minTapTarget)
        .disabled(!enabled)
    }
}
