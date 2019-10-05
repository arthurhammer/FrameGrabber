import AVFoundation
import UIKit

protocol PlaybackControllerDelegate: PlayerObserverDelegate {}

/// Manages playback for a single player item.
class PlaybackController {

    /// For now, the controller forwards player observer calls.
    weak var delegate: PlaybackControllerDelegate? {
        didSet { observer.delegate = delegate }
    }

    let player: AVPlayer

    private lazy var seeker = PlayerSeeker(player: player)
    private let observer: PlayerObserver
    private let audioSession: AVAudioSession
    private let center: NotificationCenter

    init(playerItem: AVPlayerItem, player: AVPlayer = .init(), audioSession: AVAudioSession = .sharedInstance(), center: NotificationCenter = .default) {
        self.player = player
        self.player.replaceCurrentItem(with: playerItem)
        self.player.actionAtItemEnd = .pause
        self.observer = PlayerObserver(player: player)
        self.audioSession = audioSession
        self.center = center

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

    var video: AVAsset? {
        currentItem?.asset
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

    // MARK: - Seeking

    func smoothlySeek(to time: CMTime) {
        seeker.smoothlySeek(to: time)
    }

    func directlySeek(to time: CMTime) {
        seeker.directlySeek(to: time)
    }

    private func seekToStartIfNecessary() {
        guard let item = currentItem,
           item.currentTime() >= item.duration else { return }

        directlySeek(to: .zero)
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
