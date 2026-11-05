import Core
import Foundation
import Models
import Testing
@testable import ChatFeature

@MainActor
struct GroupPhotosViewModelTests {
    private let kit = ConversationKit()

    private func picture(_ name: String) -> Photo {
        Photo(id: PhotoID(name), path: "\(name).jpg", width: 10, height: 10)
    }

    private func makeViewModel(
        _ messages: [Message]? = nil, deps: AppDependencies = .preview(.loaded), session: SessionStore? = nil
    ) -> GroupPhotosViewModel {
        let chat: any ChatRepository = messages.map { ControlledChat(base: deps.chat, messages: $0) } ?? deps.chat
        return GroupPhotosViewModel(
            conversationID: kit.crew, chat: chat, photos: ControlledPhotos(), session: session ?? deps.session)
    }

    private func start(_ viewModel: GroupPhotosViewModel) async -> Task<Void, Never> {
        let task = Task { await viewModel.run() }
        for _ in 0..<200 {
            if case .loading = viewModel.state { try? await Task.sleep(for: .milliseconds(10)) } else { break }
        }
        return task
    }

    private func photos(_ viewModel: GroupPhotosViewModel) -> [ViewerPhoto] {
        if case .loaded(let content, _) = viewModel.state { content.photos } else { [] }
    }

    @Test func theGroupsPhotosShowNewestFirst() async {
        let messages = [
            kit.message(1, from: kit.ishaID, at: 0, .photos([picture("old-a"), picture("old-b")])),
            kit.message(2, from: kit.ishaID, at: 10, .text("hi")),
            kit.message(3, from: kit.myID, at: 20, .photos([picture("new")]))
        ]
        let viewModel = makeViewModel(messages)
        let task = await start(viewModel)
        #expect(photos(viewModel).map(\.id) == ["m-3-0", "m-1-0", "m-1-1"])
        #expect(photos(viewModel).allSatisfy { $0.url != nil && !$0.label.isEmpty })
        task.cancel()
    }

    @Test func deletedMessagesAreLeftOut() async {
        var deleted = kit.message(1, from: kit.ishaID, at: 0, .photos([picture("gone")]))
        deleted.deletedAt = SampleData.day
        let messages = [deleted, kit.message(2, from: kit.ishaID, at: 5, .photos([picture("kept")]))]
        let viewModel = makeViewModel(messages)
        let task = await start(viewModel)
        #expect(photos(viewModel).map(\.id) == ["m-2-0"])
        task.cancel()
    }

    @Test func blockedPeoplesPhotosAreHidden() async {
        let deps = AppDependencies.preview(.loaded)
        deps.session.block(kit.ishaID)
        let messages = [kit.message(1, from: kit.ishaID, at: 0, .photos([picture("hidden")])),
                        kit.message(2, from: kit.myID, at: 5, .photos([picture("mine")]))]
        let viewModel = makeViewModel(messages, deps: deps)
        let task = await start(viewModel)
        #expect(photos(viewModel).map(\.id) == ["m-2-0"])
        task.cancel()
    }

    @Test func aGroupWithNoPhotosIsEmpty() async {
        let viewModel = makeViewModel([kit.message(1, from: kit.ishaID, at: 0)])
        let task = await start(viewModel)
        #expect(viewModel.state == .empty)
        task.cancel()
    }

    @Test func onlyBlockedOrDeletedPhotosIsEmptyToo() async {
        let deps = AppDependencies.preview(.loaded)
        deps.session.block(kit.ishaID)
        let viewModel = makeViewModel([kit.message(1, from: kit.ishaID, at: 0, .photos([picture("x")]))], deps: deps)
        let task = await start(viewModel)
        #expect(viewModel.state == .empty)
        task.cancel()
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let viewModel = GroupPhotosViewModel.preview(.failing)
        await viewModel.run()
        guard case .failed = viewModel.state else {
            Issue.record("expected failed, got \(viewModel.state)")
            return
        }
    }

    @Test func theSampleGroupHasPhotosAndOtherStatesLoad() async {
        let loaded = GroupPhotosViewModel.preview(.loaded)
        let task = await start(loaded)
        #expect(!photos(loaded).isEmpty)
        task.cancel()
        let empty = GroupPhotosViewModel.preview(.empty)
        let emptyTask = await start(empty)
        #expect(empty.state == .empty)
        emptyTask.cancel()
    }

    @Test func tappingAPhotoOpensTheViewerOnItWithAllOfThem() async {
        let messages = [kit.message(1, from: kit.ishaID, at: 0, .photos([picture("a"), picture("b")])),
                        kit.message(2, from: kit.myID, at: 5, .photos([picture("c")]))]
        let viewModel = makeViewModel(messages)
        let task = await start(viewModel)
        viewModel.photoTapped("m-1-1")
        #expect(viewModel.viewer?.photos.map(\.id) == ["m-2-0", "m-1-0", "m-1-1"])
        #expect(viewModel.viewer?.startIndex == 2)
        #expect(viewModel.viewer?.closeLabel.isEmpty == false)
        viewModel.viewer = nil
        viewModel.photoTapped("missing")
        #expect(viewModel.viewer == nil)
        task.cancel()
    }

    @Test func aBrokenStreamAfterPhotosKeepsThemAndMarksThemStale() async {
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat,
                                        messages: [kit.message(1, from: kit.ishaID, at: 0, .photos([picture("a")]))])
        controlled.failStreamAfterFirstBatch.withLock { $0 = true }
        let session = AppDependencies.preview(.loaded).session
        let viewModel = GroupPhotosViewModel(
            conversationID: kit.crew, chat: controlled, photos: ControlledPhotos(), session: session)
        await viewModel.run()
        guard case .loaded(let content, let isStale) = viewModel.state else {
            Issue.record("expected loaded, got \(viewModel.state)")
            return
        }
        #expect(content.photos.count == 1 && isStale)
    }
}
