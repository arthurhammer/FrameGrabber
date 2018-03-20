import UIKit
import AVKit

protocol PlayerViewControllerDelegate: class {
    func playerViewControllerDone()
}

class PlayerViewController: UIViewController {

    weak var delegate: PlayerViewControllerDelegate?

    var videoLoader: VideoLoader! {
        didSet {
            guard isViewLoaded else { return }
            loadPlayerItem()
        }
    }

    private var playbackController: PlaybackController?
    private lazy var timeFormatter = VideoTimeFormatter()

    @IBOutlet private var zoomingPlayerView: ZoomingPlayerView!
    @IBOutlet private var overlayView: PlayerOverlayView!

    private var isScrubbing: Bool {
        return overlayView.controlsView.timeSlider.isTracking
    }

    private var isSeeking: Bool {
        return playbackController?.isSeeking ?? false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        loadPlayerItem()
    }
}

// MARK: - Actions

private extension PlayerViewController {

    @IBAction func done() {
        playbackController?.pause()
        dismiss(animated: true)
        delegate?.playerViewControllerDone()
    }

    @IBAction func playOrPause() {
        guard !isScrubbing else { return }
        playbackController?.playOrPause()
    }

    func stepBackward() {
        guard !isScrubbing else { return }
        playbackController?.stepBackward()
    }

    func stepForward() {
        guard !isScrubbing else { return }
        playbackController?.stepForward()
    }

    @IBAction func shareCurrentFrame() {
        guard !isScrubbing else { return }
        playbackController?.pause()
        print("Not implemented")
    }

    @IBAction func scrub(_ sender: UISlider) {
        playbackController?.seeker.seek(to: sender.time)
        // When scrubbing, display slider time instead of player time for a smoother
        // experience.
        updateViews(withTime: sender.time)
    }

    @IBAction func didFinishScrubbing(_ sender: UISlider) {
        syncPlayerAndSliderTimeIfNeeded()
    }

    func syncPlayerAndSliderTimeIfNeeded() {
        let twoSeeksRemaining = playbackController?.seeker.nextSeek != nil

        // Minimize the time to finish seeking by replacing the two pending seeks with a
        // single final seek. This can speed up seeking for streamed iCloud items.
        if twoSeeksRemaining {
            playbackController?.seeker.seekToFinalTime()
        }
    }
}

// MARK: - PlaybackControllerDelegate

extension PlayerViewController: PlaybackControllerDelegate {

    func player(_ player: AVPlayer, didUpdateStatus status: AVPlayerStatus) {
        if status == .failed {
            showPlaybackFailedAlertAndDismiss()
        }

        updateViewsForPlayer()
    }

    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateStatus status: AVPlayerItemStatus) {
        if status == .failed {
            showPlaybackFailedAlertAndDismiss()
        }

        updateViewsForPlayer()
    }

    func player(_ player: AVPlayer, didPeriodicUpdateAtTime time: CMTime) {
        updateViews(withTime: time)
    }

    func player(_ player: AVPlayer, didUpdateTimeControlStatus status: AVPlayerTimeControlStatus) {
        updatePlayButton(withStatus: status)
    }

    func player(_ player: AVPlayer, didUpdateReasonForWaitingToPlay status: AVPlayer.WaitingReason?) {
        updateActivityIndicator()
    }

    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateDuration duration: CMTime) {
        updateSlider(withDuration: duration)
    }
}

// MARK: - Private

private extension PlayerViewController {

    func configureViews() {
        overlayView.controlsView.previousButton.repeatAction = { [weak self] in
            self?.stepBackward()
        }

        overlayView.controlsView.nextButton.repeatAction = { [weak self] in
            self?.stepForward()
        }

        // Initial states
        setPlayerControlsEnabled(false)
        updatePlayButton(withStatus: .paused)
        updateSlider(withDuration: .zero)
        updateViews(withTime: .zero)

        updateViewsForPlayer()
    }

    // MARK: Sync Player UI

    var shouldShowActivityIndicator: Bool {
        guard let playbackController = playbackController else { return true }

        return !playbackController.isReadyToPlay
            || playbackController.player.reasonForWaitingToPlay == .noItemToPlay
            || playbackController.player.reasonForWaitingToPlay == .toMinimizeStalls
    }

    func setPlayerControlsEnabled(_ enabled: Bool) {
        overlayView.controlsView.setPlayerControlsEnabled(enabled)
    }

    func updateViewsForPlayer() {
        setPlayerControlsEnabled(playbackController?.isReadyToPlay == true)
        updateActivityIndicator()
    }

    func updateActivityIndicator() {
        overlayView.controlsView.activityIndicator.isShowingAndAnimating = shouldShowActivityIndicator
    }

    func updatePlayButton(withStatus status: AVPlayerTimeControlStatus) {
        overlayView.controlsView.playButton.setTimeControlStatus(status)
    }

    func updateViews(withTime time: CMTime) {
        updateSlider(withTime: time)
        updateTimeLabel(withTime: time)
    }

    func updateTimeLabel(withTime time: CMTime) {
        let showMilliseconds = playbackController?.isPlaying == false
        let formattedTime = timeFormatter.string(fromCurrentTime: time, includeMilliseconds: showMilliseconds)
        overlayView.controlsView.timeLabel.text = formattedTime
    }

    func updateSlider(withTime time: CMTime) {
        if !isScrubbing && !isSeeking {
            overlayView.controlsView.timeSlider.time = time
        }
    }

    func updateSlider(withDuration duration: CMTime) {
        // Time is `.indefinite` when item is not ready to play
        let duration = (duration == .indefinite) ? .zero : duration
        overlayView.controlsView.timeSlider.duration = duration
    }

    // MARK: Video Loading

    func loadPlayerItem() {
        videoLoader.loadPlayerItem { [weak self] status in
            switch status {

            case .notLoaded, .loading:
                break

            case .failed(_):
                self?.showVideoLoadingFailedAlertAndDismiss()

            case .loaded(let playerItem):
                self?.configurePlayer(with: playerItem)
            }
        }
    }

    func configurePlayer(with playerItem: AVPlayerItem) {
        playbackController = PlaybackController(playerItem: playerItem)
        playbackController?.delegate = self
        zoomingPlayerView.player = playbackController?.player

        playbackController?.play()
    }

    // MARK: Alerts

    func showVideoLoadingFailedAlertAndDismiss() {
        let alertController = UIAlertController.videoLoadingFailed { [weak self] _ in
            self?.done()
        }

        present(alertController, animated: true)
    }

    func showPlaybackFailedAlertAndDismiss() {
        let alertController = UIAlertController.playbackFailed { [weak self] _ in
            self?.done()
        }

        present(alertController, animated: true)
    }
}

private extension UIButton {
    func setTimeControlStatus(_ status: AVPlayerTimeControlStatus) {
        setImage((status == .paused) ? #imageLiteral(resourceName: "play") : #imageLiteral(resourceName: "pause"), for: .normal)
    }
}
