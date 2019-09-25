import AVKit

protocol PlaybackControllerDelegate: PlayerObserverDelegate {}

/// Manages looped playback for a single player item.
class PlaybackController {

    /// For now, the controller forwards player observer calls.
    weak var delegate: PlaybackControllerDelegate? {
        didSet { observer.delegate = delegate }
    }

    var loops: Bool {
        looper != nil
    }

    let player: AVPlayer
    let seeker: PlayerSeeker
    private let observer: PlayerObserver
    private let looper: AVPlayerLooper?
    private let loopingMinimumDuration: Double = 0.8

    init(playerItem: AVPlayerItem, player: AVQueuePlayer = .init()) {
        self.player = player
        self.seeker = PlayerSeeker(player: player)
        self.observer = PlayerObserver(player: player)

        let duration = playerItem.duration

        // TODO: Currently assumes the item's status is `readyToPlay`. If it isn't, will
        // loop independent of duration (as it's `indefinite` at that point).
        if duration != .indefinite,
            duration.seconds > loopingMinimumDuration {

            self.looper = AVPlayerLooper(player: player, templateItem: playerItem)
        } else {
            self.looper = nil
            self.player.replaceCurrentItem(with: playerItem)
            self.player.actionAtItemEnd = .pause
        }
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
            !loops,
            CMTimeCompare(item.currentTime(), item.duration) >= 0 else { return }

       seeker.cancelPendingSeeks()
       currentItem?.seek(to: .zero, completionHandler: nil)
    }
}
