import AVFoundation
import Foundation

public enum MicrophonePermission: Sendable, Equatable {
    case undetermined
    case granted
    case denied
}

public enum AudioRecorderError: Error, Equatable {
    /// The person said no to the microphone (or it is switched off in Settings). The screen shows a clear message
    /// with a button to open Settings.
    case permissionDenied
    case alreadyRecording
    case notRecording
    case couldNotStart
}

/// A finished recording.
public struct VoiceNote: Sendable, Equatable {
    public let url: URL
    /// The length in whole seconds (rounded).
    public let seconds: Int
    /// True when the recording was stopped by the 2 minute limit, not by the person.
    public let hitLimit: Bool

    public init(url: URL, seconds: Int, hitLimit: Bool) {
        self.url = url
        self.seconds = seconds
        self.hitLimit = hitLimit
    }
}

/// What the recorder needs from the audio hardware. The real one wraps `AVAudioRecorder`; tests use a fake, because
/// a test host has no microphone permission.
protocol AudioRecording: AnyObject {
    func record() -> Bool
    func stop()
    var elapsed: TimeInterval { get }
    /// The current loudness from 0 (silence) to 1.
    func level() -> Float
}

/// Records a voice note: AAC, mono, 32 kbps (about 240 KB per minute) as an `.m4a` file, with a hard stop at
/// 2 minutes, a loudness level for a waveform, and the microphone permission handled. No UI here (that is the chat
/// screen). It is an `actor`, so one recording at a time and the audio objects never leave it.
public actor AudioRecorder {
    public static let maximumDuration: Duration = .seconds(120)
    /// 32 kbps is 4,000 bytes a second, so 240,000 bytes a minute.
    public static let bitRate = 32_000
    public static let bytesPerMinute = bitRate / 8 * 60
    /// How often `levels()` reports, in seconds.
    public static let levelInterval = 0.1

    static var settings: [String: Any] {
        [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 22_050, AVNumberOfChannelsKey: 1,
         AVEncoderBitRateKey: bitRate, AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue]
    }

    private let directory: URL
    private let maxDuration: Duration
    private let permission: @Sendable () -> MicrophonePermission
    private let requestPermission: @Sendable () async -> Bool
    private let makeRecording: @Sendable (URL) throws -> any AudioRecording
    private let makeID: @Sendable () -> String
    private let sleep: @Sendable (Duration) async throws -> Void

    private var recording: (any AudioRecording)?
    private var fileURL: URL?
    private var limitTask: Task<Void, Never>?
    private var finished: VoiceNote?

    public init(
        directory: URL = URL.temporaryDirectory.appending(path: "voice"), maxDuration: Duration = maximumDuration
    ) {
        self.init(
            directory: directory, maxDuration: maxDuration,
            permission: { Self.currentPermission },
            requestPermission: { await AVAudioApplication.requestRecordPermission() },
            makeRecording: { try SystemRecording(url: $0) },
            makeID: { UUID().uuidString.lowercased() },
            sleep: { try await Task.sleep(for: $0) })
    }

    init(
        directory: URL, maxDuration: Duration, permission: @escaping @Sendable () -> MicrophonePermission,
        requestPermission: @escaping @Sendable () async -> Bool,
        makeRecording: @escaping @Sendable (URL) throws -> any AudioRecording,
        makeID: @escaping @Sendable () -> String, sleep: @escaping @Sendable (Duration) async throws -> Void
    ) {
        self.directory = directory
        self.maxDuration = maxDuration
        self.permission = permission
        self.requestPermission = requestPermission
        self.makeRecording = makeRecording
        self.makeID = makeID
        self.sleep = sleep
    }

    static var currentPermission: MicrophonePermission {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: .granted
        case .denied: .denied
        default: .undetermined
        }
    }

    public var isRecording: Bool { recording != nil }

    /// Starts recording. Asks for the microphone first if the person has not decided yet.
    public func start() async throws {
        guard recording == nil else { throw AudioRecorderError.alreadyRecording }
        switch permission() {
        case .granted: break
        case .denied: throw AudioRecorderError.permissionDenied
        case .undetermined:
            guard await requestPermission() else { throw AudioRecorderError.permissionDenied }
        }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appending(path: "voice-\(makeID()).m4a")
            let started = try makeRecording(url)
            guard started.record() else { throw AudioRecorderError.couldNotStart }
            recording = started
            fileURL = url
            finished = nil
        } catch let error as AudioRecorderError {
            throw error
        } catch {
            throw AudioRecorderError.couldNotStart
        }
        let (limit, sleep) = (maxDuration, sleep)
        limitTask = Task { [weak self] in
            guard (try? await sleep(limit)) != nil else { return }
            await self?.finish(hitLimit: true)
        }
    }

    /// Stops and returns the recording. If the 2 minute limit already stopped it, this returns that recording.
    @discardableResult
    public func stop() throws -> VoiceNote {
        if recording != nil { finish(hitLimit: false) }
        guard let note = finished else { throw AudioRecorderError.notRecording }
        return note
    }

    /// Stops and throws the recording away (slide to cancel).
    public func cancel() {
        if recording != nil { finish(hitLimit: false) }
        if let note = finished { try? FileManager.default.removeItem(at: note.url) }
        finished = nil
    }

    /// The loudness (0 to 1) about ten times a second while recording, for a waveform. Ends when recording stops.
    public func levels() -> AsyncStream<Float> {
        AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled, let level = self.currentLevel() {
                    continuation.yield(level)
                    try? await Task.sleep(for: .seconds(Self.levelInterval))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func currentLevel() -> Float? { recording?.level() }

    private func finish(hitLimit: Bool) {
        guard let active = recording, let url = fileURL else { return }
        let seconds = active.elapsed
        active.stop()
        limitTask?.cancel()
        limitTask = nil
        recording = nil
        fileURL = nil
        finished = VoiceNote(url: url, seconds: Int(seconds.rounded()), hitLimit: hitLimit)
    }
}

/// The real microphone recording.
private final class SystemRecording: AudioRecording {
    private let recorder: AVAudioRecorder

    init(url: URL) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)
        recorder = try AVAudioRecorder(url: url, settings: AudioRecorder.settings)
        recorder.isMeteringEnabled = true
    }

    func record() -> Bool { recorder.record() }

    func stop() {
        recorder.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    var elapsed: TimeInterval { recorder.currentTime }

    func level() -> Float {
        recorder.updateMeters()
        let decibels = recorder.averagePower(forChannel: 0)   // about -160 (silence) to 0 (loud)
        return max(0, min(1, (decibels + 60) / 60))
    }
}
