import AVKit

enum PlayerStatus {
    /// The video or the player stack are not ready.
    case notReady
    /// The video or the player stack failed. Check the video or player stack for details about the error.
    case failed
    /// Both video and player stack are ready to play.
    case readyToPlay
}

extension Player {
    var status: PlayerStatus {
        switch (video.status, playerStack?.status) {
        case (.failed, _), (_, .failed?):
            return .failed
        case (.loaded, .readyToPlay?):
            return .readyToPlay
        default:
            return .notReady
        }
    }
}

protocol PlayerDelegate: class {
    func player(_ player: Player, didUpdateStatus status: PlayerStatus)
    func player(_ player: Player, didPeriodicUpateAt time: CMTime)
}

/// Loads an `AVPlayerItem` from a `Video` and handles playback.
/// Observes and reports status updates the video loading progress and the player stack.
class Player {

    weak var delegate: PlayerDelegate?
    let video: Video

    /// Initialized on `readyToPlay`
    private(set) var playerStack: PlayerStack?

    init(video: Video) {
        self.video = video
        loadPlayerItem()
    }

    // MARK: Playback

    var currentTime: CMTime {
        return playerStack?.player.currentTime() ?? .zero
    }

    var currentItem: AVPlayerItem? {
        return playerStack?.currentItem
    }

    /// `false` before `readyToPlay`
    var canStep: Bool {
        guard let playerItem = currentItem else { return false }
        return playerItem.canStepForward && playerItem.canStepBackward
    }

    func play() {
        playerStack?.player.play()
    }

    func pause() {
        playerStack?.player.pause()
    }

    func stepForward() {
        pause()
        playerStack?.currentItem?.step(byCount: 1)
    }

    func stepBackward() {
        pause()
        playerStack?.currentItem?.step(byCount: -1)
    }

    private var stackObserver: PlayerStackObserver?
}

// MARK: - PlayerStackObserverDelegate

extension Player: PlayerStackObserverDelegate {

    func didUpdateStatus(_ status: PlayerStackStatus, of stack: PlayerStack) {
        delegate?.player(self, didUpdateStatus: self.status)
    }

    func didPeriodicUpdate(at time: CMTime) {
        delegate?.player(self, didPeriodicUpateAt: time)
    }
}

// MARK: - Private

private extension Player {

    func loadPlayerItem() {
        video.loadPlayerItem { [weak self] video, status in
            guard let this = self else { return }

            if case let .loaded(playerItem) = status {
                this.playerItemDidLoad(playerItem)
            }

            this.delegate?.player(this, didUpdateStatus: this.status)
        }
    }

    func playerItemDidLoad(_ playerItem: AVPlayerItem) {
        // Setup up playback and play
        playerStack = PlayerStack(loopingTemplateItem: playerItem)
        stackObserver = PlayerStackObserver(stack: playerStack!)
        stackObserver!.delegate = self
        play()
    }

    func cancelLoadingPlayerItem() {
        video.cancelLoadingPlayerItem()
    }
}
