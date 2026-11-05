import AVFoundation
import Foundation
import Synchronization
import Testing
@testable import Core

/// A recording that needs no microphone: it reports a loudness that rises, and the time the test says it ran for.
private final class FakeRecording: AudioRecording, Sendable {
    private let state = Mutex((running: false, stops: 0, elapsed: 0.0, level: Float(0.1)))
    let accepts: Bool

    init(accepts: Bool = true) { self.accepts = accepts }

    func setElapsed(_ seconds: Double) { state.withLock { $0.elapsed = seconds } }
    var stopCount: Int { state.withLock { $0.stops } }

    func record() -> Bool {
        state.withLock { $0.running = accepts }
        return accepts
    }

    func stop() { state.withLock { $0.running = false; $0.stops += 1 } }

    var elapsed: TimeInterval { state.withLock { $0.elapsed } }

    func level() -> Float {
        state.withLock { $0.level = min(1, $0.level + 0.1); return $0.level }
    }
}

private final class Counter: Sendable {
    private let count = Mutex(0)
    func next() -> String { count.withLock { $0 += 1; return "\($0)" } }
}

struct AudioRecorderTests {
    private func makeRecorder(
        permission: MicrophonePermission = .granted, asks: Bool = true, limit: Duration = .seconds(120),
        recording: FakeRecording = FakeRecording(), elapsedAtStop: Double = 3.4
    ) -> AudioRecorder {
        recording.setElapsed(elapsedAtStop)
        let ids = Counter()
        return AudioRecorder(
            directory: URL.temporaryDirectory.appending(path: "vybe-voice-\(UUID().uuidString)"), maxDuration: limit,
            permission: { permission }, requestPermission: { asks }, makeRecording: { _ in recording },
            makeID: { ids.next() }, sleep: { try await Task.sleep(for: $0) })
    }

    // MARK: The numbers the task asks for

    @Test func theRecordingFormatIsAACMonoAt32Kbps() {
        let settings = AudioRecorder.settings
        #expect(settings[AVFormatIDKey] as? UInt32 == kAudioFormatMPEG4AAC)
        #expect(settings[AVNumberOfChannelsKey] as? Int == 1)
        #expect(settings[AVEncoderBitRateKey] as? Int == 32_000)
    }

    @Test func thatBitrateIsAbout240KilobytesAMinute() {
        #expect(AudioRecorder.bytesPerMinute == 240_000)
        // Two minutes, the longest allowed, is under half a megabyte.
        #expect(AudioRecorder.bytesPerMinute * 2 == 480_000)
    }

    @Test func theHardLimitIsTwoMinutes() {
        #expect(AudioRecorder.maximumDuration == .seconds(120))
    }

    // MARK: Recording

    @Test func recordingStartsAndStopsWithAnM4AFile() async throws {
        let recorder = makeRecorder(elapsedAtStop: 3.6)
        try await recorder.start()
        #expect(await recorder.isRecording)
        let note = try await recorder.stop()
        #expect(note.url.pathExtension == "m4a" && note.url.lastPathComponent == "voice-1.m4a")
        #expect(note.seconds == 4 && !note.hitLimit)
        #expect(await !recorder.isRecording)
    }

    @Test func recordingStopsByItselfAtTheLimit() async throws {
        // A short limit is injected, as the task asks, instead of waiting two minutes.
        let recording = FakeRecording()
        let recorder = makeRecorder(limit: .milliseconds(150), recording: recording, elapsedAtStop: 0.15)
        try await recorder.start()
        // Wait for the automatic stop instead of a fixed time: a slow CI machine needs longer than a laptop.
        for _ in 0..<100 where await recorder.isRecording {
            try await Task.sleep(for: .milliseconds(100))
        }
        #expect(await !recorder.isRecording)
        #expect(recording.stopCount == 1)
        let note = try await recorder.stop()   // still available after the automatic stop
        #expect(note.hitLimit)
    }

    @Test func stoppingEarlyCancelsTheLimitTimer() async throws {
        let recording = FakeRecording()
        let recorder = makeRecorder(limit: .milliseconds(200), recording: recording)
        try await recorder.start()
        let note = try await recorder.stop()
        try await Task.sleep(for: .milliseconds(400))
        #expect(!note.hitLimit && recording.stopCount == 1)   // the timer did not stop it a second time
    }

    @Test func cancelThrowsTheRecordingAway() async throws {
        let recorder = makeRecorder()
        try await recorder.start()
        await recorder.cancel()
        #expect(await !recorder.isRecording)
        await #expect(throws: AudioRecorderError.notRecording) { try await recorder.stop() }
    }

    @Test func onlyOneRecordingAtATime() async throws {
        let recorder = makeRecorder()
        try await recorder.start()
        await #expect(throws: AudioRecorderError.alreadyRecording) { try await recorder.start() }
    }

    @Test func stoppingWithoutRecordingIsAnError() async {
        let recorder = makeRecorder()
        await #expect(throws: AudioRecorderError.notRecording) { try await recorder.stop() }
    }

    @Test func aSecondRecordingGetsItsOwnFile() async throws {
        let recorder = makeRecorder()
        try await recorder.start()
        let first = try await recorder.stop()
        try await recorder.start()
        let second = try await recorder.stop()
        #expect(first.url != second.url)
    }

    @Test func aRecorderThatCannotStartIsAClearError() async {
        let recorder = makeRecorder(recording: FakeRecording(accepts: false))
        await #expect(throws: AudioRecorderError.couldNotStart) { try await recorder.start() }
        #expect(await !recorder.isRecording)
    }

    // MARK: Permission

    @Test func aDeniedMicrophoneIsAClearErrorState() async {
        let recorder = makeRecorder(permission: .denied)
        await #expect(throws: AudioRecorderError.permissionDenied) { try await recorder.start() }
        #expect(await !recorder.isRecording)
    }

    @Test func anUndecidedMicrophoneAsksAndRecordsWhenAllowed() async throws {
        let recorder = makeRecorder(permission: .undetermined, asks: true)
        try await recorder.start()
        #expect(await recorder.isRecording)
    }

    @Test func anUndecidedMicrophoneThatIsRefusedIsPermissionDenied() async {
        let recorder = makeRecorder(permission: .undetermined, asks: false)
        await #expect(throws: AudioRecorderError.permissionDenied) { try await recorder.start() }
    }

    // MARK: Levels

    @Test func levelsArriveWhileRecordingAndEndWhenItStops() async throws {
        let recorder = makeRecorder()
        try await recorder.start()
        var heard: [Float] = []
        for await level in await recorder.levels() {
            heard.append(level)
            if heard.count == 3 { try await recorder.stop() }
        }
        #expect(heard.count >= 3)
        #expect(heard.allSatisfy { (0...1).contains($0) })
        #expect(heard == heard.sorted())   // the fake gets louder
    }

    @Test func levelsOfAnIdleRecorderEndAtOnce() async {
        let recorder = makeRecorder()
        var count = 0
        for await _ in await recorder.levels() { count += 1 }
        #expect(count == 0)
    }

    @Test func theRealRecorderSaysWhereItStandsOnPermission() {
        // Reading the status needs no microphone and must not prompt.
        let status = AudioRecorder.currentPermission
        #expect([.undetermined, .granted, .denied].contains(status))
    }
}

/// A player that needs no speaker: a clock the test moves by hand.
private final class FakePlayback: AudioPlaying, Sendable {
    private let state = Mutex((time: 0.0, playing: false))
    let duration: TimeInterval

    init(duration: TimeInterval) { self.duration = duration }

    var currentTime: TimeInterval {
        get { state.withLock { $0.time } }
        set { state.withLock { $0.time = newValue } }
    }

    var isPlaying: Bool { state.withLock { $0.playing } }

    func play() -> Bool {
        state.withLock { $0.playing = true }
        return true
    }

    func pause() { state.withLock { $0.playing = false } }

    /// The sound moved on by itself.
    func advance(to time: TimeInterval) {
        state.withLock {
            $0.time = min(time, duration)
            if $0.time >= duration { $0.playing = false }
        }
    }
}

@MainActor
struct AudioPlayerTests {
    private func makePlayer(duration: TimeInterval = 10) -> (AudioPlayer, FakePlayback) {
        let playback = FakePlayback(duration: duration)
        return (AudioPlayer(tick: .milliseconds(5), makePlayback: { _ in playback }), playback)
    }

    private let url = URL(filePath: "/tmp/EXAMPLE.m4a")

    @Test func loadingShowsTheLength() throws {
        let (player, _) = makePlayer(duration: 42)
        #expect(!player.isLoaded && player.duration == 0 && player.progress == 0)
        try player.load(url: url)
        #expect(player.isLoaded && player.duration == 42 && player.currentTime == 0 && !player.isPlaying)
    }

    @Test func playAndPauseSwitchTheState() throws {
        let (player, _) = makePlayer()
        try player.load(url: url)
        player.play()
        #expect(player.isPlaying)
        player.pause()
        #expect(!player.isPlaying)
        player.toggle()
        #expect(player.isPlaying)
        player.toggle()
        #expect(!player.isPlaying)
    }

    @Test func playingBeforeLoadingDoesNothing() {
        let (player, _) = makePlayer()
        player.play()
        player.seek(toSeconds: 3)
        #expect(!player.isPlaying && player.currentTime == 0)
    }

    @Test func progressFollowsThePlayback() async throws {
        let (player, playback) = makePlayer(duration: 10)
        try player.load(url: url)
        player.play()
        playback.advance(to: 2.5)
        for _ in 0..<100 where player.currentTime != 2.5 { try await Task.sleep(for: .milliseconds(50)) }
        #expect(player.currentTime == 2.5 && player.progress == 0.25)
    }

    @Test func seekingJumpsAndIsClamped() throws {
        let (player, playback) = makePlayer(duration: 10)
        try player.load(url: url)
        player.seek(toSeconds: 4)
        #expect(player.currentTime == 4 && playback.currentTime == 4)
        player.seek(toProgress: 0.5)
        #expect(player.currentTime == 5)
        player.seek(toSeconds: 99)
        #expect(player.currentTime == 10 && player.progress == 1)
        player.seek(toSeconds: -5)
        #expect(player.currentTime == 0)
        player.seek(toProgress: 3)
        #expect(player.currentTime == 10)
    }

    @Test func playbackEndsByItselfAndPlayingAgainStartsOver() async throws {
        let (player, playback) = makePlayer(duration: 4)
        try player.load(url: url)
        player.play()
        playback.advance(to: 4)
        for _ in 0..<100 where player.isPlaying { try await Task.sleep(for: .milliseconds(50)) }
        #expect(!player.isPlaying && player.currentTime == 4 && player.progress == 1)
        player.play()
        #expect(player.isPlaying && playback.currentTime == 0)
    }

    @Test func loadingAnotherNoteStopsTheFirst() throws {
        let (player, first) = makePlayer(duration: 10)
        try player.load(url: url)
        player.play()
        try player.load(url: url)
        #expect(!first.isPlaying && !player.isPlaying && player.currentTime == 0)
    }

    @Test func aMissingFileCannotBeLoaded() {
        let player = AudioPlayer()
        #expect(throws: (any Error).self) { try player.load(url: URL(filePath: "/nonexistent/EXAMPLE.m4a")) }
        #expect(!player.isLoaded)
    }

    @Test func aRealAudioFileReportsItsLength() throws {
        let url = URL.temporaryDirectory.appending(path: "vybe-test-\(UUID().uuidString).wav")
        defer { try? FileManager.default.removeItem(at: url) }
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 8_000, channels: 1))
        do {
            // The file is only complete on disk once the writer is released, so it lives inside this block.
            let file = try AVAudioFile(forWriting: url, settings: format.settings)
            let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4_000))
            buffer.frameLength = 4_000   // half a second of silence
            try file.write(from: buffer)
        }

        let player = AudioPlayer()
        try player.load(url: url)
        #expect(abs(player.duration - 0.5) < 0.01 && !player.isPlaying)
    }
}
