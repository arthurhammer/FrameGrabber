import AVKit

protocol PlaybackControllerDelegate: PlayerObserverDelegate {}

/// Manages looped playback for a single player item.
class PlaybackController {

    /// For now, the controller simply forwards the playback observer delegate calls
    weak var delegate: PlaybackControllerDelegate? {
        didSet { observer.delegate = delegate }
    }

    let player: AVPlayer
    let seeker: PlayerSeeker
    private let looper: AVPlayerLooper
    private let observer: PlayerObserver

    init(playerItem: AVPlayerItem, player: AVQueuePlayer = .init()) {
        self.player = player
        self.looper = AVPlayerLooper(player: player, templateItem: playerItem)
        self.seeker = PlayerSeeker(player: player)
        self.observer = PlayerObserver(player: player)
    }

    // MARK: Status

    /// True when both the player and the current item are ready to play.
    var isReadyToPlay: Bool {
        return (player.status == .readyToPlay) && (currentItem?.status == .readyToPlay)
    }

    /// True if the player is playing or waiting to play.
    /// Check `player.timeControlStatus` for a more detailed state.
    var isPlaying: Bool {
        return player.rate != 0
    }

    var isSeeking: Bool {
        return seeker.isSeeking
    }

    var currentTime: CMTime {
        return player.currentTime()
    }

    var currentItem: AVPlayerItem? {
        return player.currentItem
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
        syncPlayerAndSeekTimeForPlayingIfNeeded()
        player.play()
    }

    func pause() {
        guard isPlaying else { return }
        player.pause()
    }

    // MARK: Stepping

    func stepBackward() {
        step(byCount: -1)
    }

    func stepForward() {
        step(byCount: 1)
    }

    func step(byCount count: Int) {
        pause()
        syncPlayerAndSeekTimeForSteppingIfNeeded(isSteppingForward: count > 0)
        currentItem?.step(byCount: count)
    }

    // MARK: Seek Time Syncing

    private func syncPlayerAndSeekTimeForPlayingIfNeeded() {
        guard isSeeking else { return }

        // Minimize the time to start playing by finishing seeking earlier with a higher
        // tolerance. This is mostly relevant for streamed iCloud items.
        seeker.seekToFinalTime(withToleranceBefore: .positiveInfinity, toleranceAfter: .positiveInfinity)
    }

    private func syncPlayerAndSeekTimeForSteppingIfNeeded(isSteppingForward: Bool) {
        guard isSeeking else { return }

        // By default, stepping while seeking cancels seeking and steps from the current
        // player time. Instead, we want to step from the seek time. By replacing the current
        // seek with one with higher tolerance we (most likely) get the new seek to finish
        // before stepping begins. This is mostly relevant for streamed iCloud items.

        if isSteppingForward {
            seeker.seekToFinalTime(withToleranceBefore: .zero, toleranceAfter: .positiveInfinity)
        } else {
            seeker.seekToFinalTime(withToleranceBefore: .positiveInfinity, toleranceAfter: .zero)
        }
    }
}
