import Components
import Core
import Foundation
import Models
import Testing
@testable import ChatFeature

@MainActor
struct ConversationPhotosTests {
    private let kit = ConversationKit()

    private func makeViewModel(
        _ id: ConversationID? = nil, chat: (any ChatRepository)? = nil, photos: ControlledPhotos = ControlledPhotos(),
        offline: Bool = false
    ) -> ConversationViewModel {
        kit.makeViewModel(id, chat: chat, offline: offline, photos: photos)
    }

    private func sentPhotos(_ controlled: ControlledChat) -> [[Photo]] {
        controlled.sent.withLock { list in
            list.compactMap { if case .photos(let photos) = $0.1 { photos } else { nil } }
        }
    }

    @Test func pickedPhotosAreMadeSafeSavedAndSentAsOneMessage() async throws {
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat)
        let photos = ControlledPhotos()
        let viewModel = makeViewModel(chat: controlled, photos: photos)
        let task = await kit.open(viewModel)
        let original = try TestPhotos.jpegWithLocation()
        #expect(TestPhotos.hasLocation(original))
        await viewModel.photosPicked([original, original])
        #expect(photos.saved.withLock { $0.count } == 2)
        // What was saved has gone through PhotoProcessor: the location is gone.
        for processed in photos.saved.withLock({ $0 }) {
            #expect(!TestPhotos.hasLocation(processed.large) && !TestPhotos.hasLocation(processed.thumbnail))
        }
        #expect(sentPhotos(controlled).count == 1)
        #expect(sentPhotos(controlled).first?.count == 2)
        #expect(viewModel.notice == nil && !viewModel.isSendingPhotos)
        task.cancel()
    }

    @Test func atMostTwoPhotosGoInOneMessage() async throws {
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat)
        let photos = ControlledPhotos()
        let viewModel = makeViewModel(chat: controlled, photos: photos)
        let task = await kit.open(viewModel)
        let original = try TestPhotos.jpegWithLocation()
        await viewModel.photosPicked([original, original, original])
        #expect(ConversationViewModel.photoLimit == 2)
        #expect(sentPhotos(controlled).first?.count == 2)
        #expect(photos.saved.withLock { $0.count } == 2)
        task.cancel()
    }

    @Test func somethingThatIsNotAPictureSendsNothingAndSaysSo() async {
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat)
        let photos = ControlledPhotos()
        let viewModel = makeViewModel(chat: controlled, photos: photos)
        let task = await kit.open(viewModel)
        await viewModel.photosPicked([Data("not a picture".utf8)])
        #expect(viewModel.notice == viewModel.photoFailedNotice)
        #expect(sentPhotos(controlled).isEmpty && photos.saved.withLock { $0.isEmpty })
        #expect(!viewModel.isSendingPhotos)
        task.cancel()
    }

    @Test func oneBadPictureAmongTwoSendsNothing() async throws {
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat)
        let viewModel = makeViewModel(chat: controlled)
        let task = await kit.open(viewModel)
        await viewModel.photosPicked([try TestPhotos.jpegWithLocation(), Data("nope".utf8)])
        #expect(viewModel.notice != nil)
        #expect(sentPhotos(controlled).isEmpty)
        task.cancel()
    }

    @Test func aFailedSaveSendsNothingAndSaysSo() async throws {
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat)
        let photos = ControlledPhotos()
        photos.failSave.withLock { $0 = true }
        let viewModel = makeViewModel(chat: controlled, photos: photos)
        let task = await kit.open(viewModel)
        await viewModel.photosPicked([try TestPhotos.jpegWithLocation()])
        #expect(viewModel.notice == viewModel.photoFailedNotice)
        #expect(sentPhotos(controlled).isEmpty)
        task.cancel()
    }

    @Test func aFailedSendShowsTheReason() async throws {
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat)
        controlled.failSend.withLock { $0 = true }
        let viewModel = makeViewModel(chat: controlled)
        let task = await kit.open(viewModel)
        await viewModel.photosPicked([try TestPhotos.jpegWithLocation()])
        #expect(viewModel.notice != nil && !viewModel.isSendingPhotos)
        task.cancel()
    }

    @Test func thePickerCouldNotReadAPictureSaysSo() {
        let viewModel = makeViewModel()
        viewModel.photoLoadFailed()
        #expect(viewModel.notice == viewModel.photoFailedNotice)
    }

    @Test func offlineMutedAndRecordingTurnPhotosOff() async throws {
        let offline = makeViewModel(offline: true)
        #expect(!offline.canAddPhotos)
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat)
        await offline.photosPicked([try TestPhotos.jpegWithLocation()])
        #expect(sentPhotos(controlled).isEmpty && offline.notice == nil)

        let muted = ControlledChat(base: StubChatRepository(store: SocialStubStore(mutedIn: [kit.crew])))
        let mutedModel = makeViewModel(chat: muted)
        let task = await kit.open(mutedModel)
        #expect(!mutedModel.canAddPhotos)
        await mutedModel.photosPicked([try TestPhotos.jpegWithLocation()])
        #expect(sentPhotos(muted).isEmpty)
        task.cancel()

        let recording = makeViewModel()
        recording.isRecording = true
        #expect(!recording.canAddPhotos)
    }

    @Test func anOnlineMemberCanAddPhotos() async {
        let viewModel = makeViewModel()
        let task = await kit.open(viewModel)
        #expect(viewModel.canAddPhotos)
        task.cancel()
    }

    @Test func aPhotoMessageShowsTheRealPicturesFromThePhotoStore() async {
        let pictures = [Photo(id: "ph1", path: "one.jpg", width: 10, height: 10),
                        Photo(id: "ph2", path: "two.jpg", width: 10, height: 10)]
        let fixed = [kit.message(1, from: kit.ishaID, at: 0, .photos(pictures))]
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat, messages: fixed)
        let viewModel = makeViewModel(chat: controlled)
        let task = await kit.open(viewModel)
        if case .photos(let urls)? = kit.rows(viewModel).first?.content {
            #expect(urls.count == 2 && urls.allSatisfy { $0 != nil })
        } else {
            Issue.record("the row is not a photo row")
        }
        task.cancel()
    }

    @Test func tappingAPhotoOpensTheViewerOnThatPhotoWithAllOfThem() async {
        let pictures = [Photo(id: "ph1", path: "one.jpg", width: 10, height: 10),
                        Photo(id: "ph2", path: "two.jpg", width: 10, height: 10)]
        let fixed = [kit.message(1, from: kit.ishaID, at: 0, .photos(pictures)),
                     kit.message(2, from: kit.ishaID, at: 5)]
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat, messages: fixed)
        let viewModel = makeViewModel(chat: controlled)
        let task = await kit.open(viewModel)
        viewModel.photoTapped("m-1", at: 1)
        #expect(viewModel.viewer?.photos.count == 2)
        #expect(viewModel.viewer?.startIndex == 1)
        #expect(viewModel.viewer?.photos.allSatisfy { $0.url != nil && !$0.label.isEmpty } == true)
        #expect(viewModel.viewer?.closeLabel.isEmpty == false)
        viewModel.viewer = nil
        viewModel.photoTapped("m-2", at: 0)   // a text message
        viewModel.photoTapped("m-1", at: 5)   // out of range
        viewModel.photoTapped("missing", at: 0)
        #expect(viewModel.viewer == nil)
        task.cancel()
    }
}
