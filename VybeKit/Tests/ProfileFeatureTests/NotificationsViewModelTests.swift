import Core
import Foundation
import Models
import Testing
@testable import ProfileFeature

@MainActor
struct NotificationsViewModelTests {
    /// Stands in for wherever the choices will be kept.
    private final class Memory {
        var saved = NotificationChoices()
        var failSaves = false
    }

    private func make(_ memory: Memory) -> NotificationsViewModel {
        NotificationsViewModel(
            loadChoices: { memory.saved },
            saveChoices: { choices in
                if memory.failSaves { throw AppError.offline }
                memory.saved = choices
            })
    }

    private func switches(_ viewModel: NotificationsViewModel) -> [NotificationSwitch] {
        if case .loaded(let items, _) = viewModel.state { return items }
        return []
    }

    @Test func everyEventHasASwitchAndAllStartOn() async {
        let viewModel = make(Memory())
        await viewModel.load()
        #expect(switches(viewModel).map(\.kind) == NotificationSwitch.Kind.allCases)
        #expect(switches(viewModel).allSatisfy { $0.isOn })
    }

    @Test func aChangeIsSavedAndReadBack() async {
        let memory = Memory()
        let viewModel = make(memory)
        await viewModel.load()
        await viewModel.setSwitch(.likes, isOn: false)
        #expect(!memory.saved.likes && memory.saved.comments)
        let again = make(memory)
        await again.load()
        #expect(switches(again).first { $0.kind == .likes }?.isOn == false)
    }

    @Test func aFailedSaveFlipsTheSwitchBack() async {
        let memory = Memory()
        memory.failSaves = true
        let viewModel = make(memory)
        await viewModel.load()
        await viewModel.setSwitch(.messages, isOn: false)
        #expect(viewModel.saveFailed)
        #expect(switches(viewModel).first { $0.kind == .messages }?.isOn == true)
    }
}
