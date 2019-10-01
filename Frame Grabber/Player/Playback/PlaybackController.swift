import AVKit
import UIKit

protocol PlaybackControllerDelegate: PlayerObserverDelegate {}

/// Manages playback for a single player item.
class PlaybackController {

    /// For now, the controller forwards player observer calls.
    weak var delegate: PlaybackControllerDelegate? {
        didSet { observer.delegate = delegate }
    }

    let player: AVPlayer
    let seeker: PlayerSeeker
    let audioSession = AVAudioSession.sharedInstance()
    let center = NotificationCenter.default
    private let observer: PlayerObserver

    init(playerItem: AVPlayerItem, player: AVPlayer = .init()) {
        self.player = player
        self.player.replaceCurrentItem(with: playerItem)
        self.player.actionAtItemEnd = .pause
        self.seeker = PlayerSeeker(player: player)
        self.observer = PlayerObserver(player: player)

        configureAudioSession()
    }

    // MARK: Status

    /// True when both the player and the current item are ready to play.
    var isReadyToPlay: Bool {
        (player.status == .readyToPlay) && (currentItem?.status == .readyToPlay)
    }

    /// True if the player is playing or waiting to play.
    /// Check `player.timeControlStatus` for detailed status.
    var isPlaying: Bool {
        player.rate != 0
    }

    var isSeeking: Bool {
        seeker.isSeeking
    }

    var currentTime: CMTime {
        player.currentTime()
    }

    var currentItem: AVPlayerItem? {
        player.currentItem
    }

    /// This property can change during playback.
    var frameRate: Float? {
        currentItem?.asset.tracks(withMediaType: .video).first?.nominalFrameRate
    }

    /// This property can change during playback.
    var dimensions: CGSize? {
        currentItem?.asset.tracks(withMediaType: .video).first?.naturalSize
    }

    // MARK: Playback

    func playOrPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func play() {
        guard !isPlaying else { return }

        seekToStartIfNecessary()
        player.play()
    }

    func pause() {
        guard isPlaying else { return }
        player.pause()
    }

    func step(byCount count: Int) {
        pause()
        currentItem?.step(byCount: count)
    }

    private func seekToStartIfNecessary() {
        guard let item = currentItem,
           CMTimeCompare(item.currentTime(), item.duration) >= 0 else { return }

        seeker.cancelPendingSeeks()
        seeker.smoothlySeek(to: .zero)
    }

    // MARK: - Handling Audio Session

    private func configureAudioSession() {
        try? audioSession.setCategory(.ambient)
        center.addObserver(self, selector: #selector(updateAudioSession), name: AVAudioSession.silenceSecondaryAudioHintNotification, object: audioSession)
        center.addObserver(self, selector: #selector(updateAudioSession), name: UIApplication.willResignActiveNotification, object: nil)
        center.addObserver(self, selector: #selector(updateAudioSession), name: UIApplication.didBecomeActiveNotification, object: nil)
        updateAudioSession()
    }

    @objc private func updateAudioSession() {
        player.isMuted = audioSession.secondaryAudioShouldBeSilencedHint
    }
}
