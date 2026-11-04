import AVFoundation
import Foundation
import Observation

/// What the player needs from the audio hardware. The real one wraps `AVAudioPlayer`; tests use a fake.
protocol AudioPlaying: AnyObject {
    var duration: TimeInterval { get }
    var currentTime: TimeInterval { get set }
    var isPlaying: Bool { get }
    func play() -> Bool
    func pause()
}

/// Plays one voice note: play, pause, seek and progress. No UI here (that is the chat screen). Like the stores it is
/// `@MainActor @Observable`, because a screen reads its progress while it plays.
@MainActor @Observable
public final class AudioPlayer {
    public private(set) var isPlaying = false
    /// Seconds played so far.
    public private(set) var currentTime: TimeInterval = 0
    public private(set) var duration: TimeInterval = 0

    private var playback: (any AudioPlaying)?
    private var ticker: Task<Void, Never>?
    private let makePlayback: (URL) throws -> any AudioPlaying
    private let tick: Duration

    public init() {
        makePlayback = { try SystemPlayback(url: $0) }
        tick = .milliseconds(100)
    }

    init(tick: Duration = .milliseconds(10), makePlayback: @escaping (URL) throws -> any AudioPlaying) {
        self.makePlayback = makePlayback
        self.tick = tick
    }

    /// 0 at the start, 1 at the end.
    public var progress: Double { duration > 0 ? min(1, max(0, currentTime / duration)) : 0 }

    public var isLoaded: Bool { playback != nil }

    /// Loads a file and stops whatever was playing. Throws if the file cannot be read as audio.
    public func load(url: URL) throws {
        stopTicking()
        playback?.pause()
        let loaded = try makePlayback(url)
        playback = loaded
        duration = loaded.duration
        currentTime = 0
        isPlaying = false
    }

    public func play() {
        guard let playback, !isPlaying else { return }
        if progress >= 1 { seek(toSeconds: 0) }
        guard playback.play() else { return }
        isPlaying = true
        startTicking()
    }

    public func pause() {
        playback?.pause()
        isPlaying = false
        stopTicking()
        refresh()
    }

    public func toggle() {
        if isPlaying { pause() } else { play() }
    }

    /// Jumps to a time (clamped to the recording).
    public func seek(toSeconds seconds: TimeInterval) {
        guard let playback else { return }
        playback.currentTime = min(max(0, seconds), duration)
        refresh()
    }

    /// Jumps to a place from 0 (start) to 1 (end), for a scrubber.
    public func seek(toProgress fraction: Double) {
        seek(toSeconds: duration * min(max(0, fraction), 1))
    }

    private func refresh() {
        guard let playback else { return }
        currentTime = playback.currentTime
        if isPlaying, !playback.isPlaying {   // it reached the end by itself
            isPlaying = false
            currentTime = duration
            stopTicking()
        }
    }

    private func startTicking() {
        stopTicking()
        let interval = tick
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: interval)
                guard let self, !Task.isCancelled else { return }
                self.refresh()
            }
        }
    }

    private func stopTicking() {
        ticker?.cancel()
        ticker = nil
    }
}

/// The real audio file playback.
private final class SystemPlayback: AudioPlaying {
    private let player: AVAudioPlayer

    init(url: URL) throws {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        player = try AVAudioPlayer(contentsOf: url)
        player.prepareToPlay()
    }

    var duration: TimeInterval { player.duration }

    var currentTime: TimeInterval {
        get { player.currentTime }
        set { player.currentTime = newValue }
    }

    var isPlaying: Bool { player.isPlaying }

    func play() -> Bool {
        try? AVAudioSession.sharedInstance().setActive(true)
        return player.play()
    }

    func pause() { player.pause() }
}
