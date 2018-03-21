import UIKit
import AVKit

protocol PlayerViewControllerDelegate: class {
    func playerViewControllerDone()
}

class PlayerViewController: UIViewController {

    weak var delegate: PlayerViewControllerDelegate?

    var videoLoader: VideoLoader!

    private var playbackController: PlaybackController?
    private lazy var timeFormatter = VideoTimeFormatter()
    private lazy var dimensionFormatter = VideoDimensionFormatter()

    @IBOutlet private var zoomingPlayerView: ZoomingPlayerView!
    @IBOutlet private var loadingView: PlayerLoadingView!
    @IBOutlet private var overlayView: PlayerOverlayView!

    private var isScrubbing: Bool {
        return overlayView.controlsView.timeSlider.isTracking
    }

    private var isSeeking: Bool {
        return playbackController?.isSeeking ?? false
    }

    private var isGeneratingFrame = false {
        didSet {
            updateActivityIndicator()
            updatePlayerControlsEnabled()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        loadVideo()
    }
}

// MARK: - Actions

private extension PlayerViewController {

    @IBAction func done() {
        videoLoader.cancelAllRequests()
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
        guard !isScrubbing,
            let item = playbackController?.currentItem else { return }

        playbackController?.pause()
        playbackController?.seeker.syncPlayerWithSeekTimeForImageExportIfNeeded()

        generateFrameAndShare(from: item.asset, at: item.currentTime())
    }

    @IBAction func scrub(_ sender: UISlider) {
        playbackController?.seeker.smoothlySeek(to: sender.time)
        // When scrubbing, display slider time instead of player time.
        updateViews(withTime: sender.time)
    }

    @IBAction func didFinishScrubbing(_ sender: UISlider) {
        playbackController?.seeker.syncPlayerWithSeekTimeForFinishScrubbingIfNeeded()
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

    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdatePresentationSize size: CGSize) {
        updateDimensionsLabel(withSize: size)
    }
}

// MARK: - ZoomingPlayerViewDelegate

extension PlayerViewController: ZoomingPlayerViewDelegate {
    func playerView(_ playerView: ZoomingPlayerView, didUpdateReadyForDisplay ready: Bool) {
        updatePreviewImage()
    }
}

// MARK: - Private

private extension PlayerViewController {

    func configureViews() {
        zoomingPlayerView.delegate = self

        overlayView.controlsView.previousButton.repeatAction = { [weak self] in
            self?.stepBackward()
        }

        overlayView.controlsView.nextButton.repeatAction = { [weak self] in
            self?.stepForward()
        }

        // Initial states
        updatePlayButton(withStatus: .paused)
        updateSlider(withDuration: .zero)
        updateViews(withTime: .zero)
        updateDimensionsLabel(withSize: .zero)
        updateViewsForPlayer()
    }

    // MARK: Sync Player UI

    var shouldDisableControls: Bool {
        guard let playbackController = playbackController else { return true }

        return !playbackController.isReadyToPlay
            || isGeneratingFrame
    }

    var shouldShowActivityIndicator: Bool {
        return shouldDisableControls
            || playbackController?.player.reasonForWaitingToPlay == .noItemToPlay
            || playbackController?.player.reasonForWaitingToPlay == .toMinimizeStalls
    }

    func updatePlayerControlsEnabled() {
        overlayView.controlsView.setPlayerControlsEnabled(!shouldDisableControls)
    }

    func updateViewsForPlayer() {
        updatePlayerControlsEnabled()
        updatePreviewImage()
        updateActivityIndicator()
    }

    func updatePreviewImage() {
        let readyToPlay = playbackController?.isReadyToPlay == true
        let readyToDisplay = zoomingPlayerView.playerView.playerLayer.isReadyForDisplay
        let hasPreview = loadingView.previewImageView.image != nil

        loadingView.previewImageView.isHidden = !hasPreview || (readyToPlay && readyToDisplay)

        // Preview not needed anymore in case still loading
        if readyToPlay && readyToDisplay {
            videoLoader.imageRequest?.cancel()
        }
    }

    func updateActivityIndicator() {
        loadingView.activityIndicator.isShowingAndAnimating = shouldShowActivityIndicator
    }

    func updatePlayButton(withStatus status: AVPlayerTimeControlStatus) {
        overlayView.controlsView.playButton.setTimeControlStatus(status)
    }

    func updateDimensionsLabel(withSize size: CGSize) {
        // Prefer player item size if available, might be different from Photos asset size
        let playerItemSize = size
        let phAssetSize = CGSize(width: videoLoader.asset.pixelWidth, height: videoLoader.asset.pixelHeight)
        let size = (playerItemSize == .zero) ? phAssetSize : playerItemSize

        let dimensions = dimensionFormatter.string(from: size)
        overlayView.titleView.detailTitleLabel.text = dimensions
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

    func loadVideo() {
        loadPreviewImage()
        loadPlayerItem()
    }

    func loadPreviewImage() {
        let size = loadingView.previewImageView.bounds.size.scaledToScreen

        videoLoader.image(withSize: size, contentMode: .aspectFit) { [weak self] image, _ in
            guard let image = image else { return }
            self?.loadingView.previewImageView.image = image
            self?.updatePreviewImage()
        }
    }

    func loadPlayerItem() {
        videoLoader.playerItem { [weak self] playerItem, info in
            if info.error != nil {
                self?.showVideoLoadingFailedAlertAndDismiss()
            } else if !info.isCancelled, let playerItem = playerItem {
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

    // MARK: Image Generation

    func generateFrameAndShare(from asset: AVAsset, at time: CMTime) {
        isGeneratingFrame = true

        videoLoader.frame(for: asset, at: time) { [weak self] _, cgImage, _, status, error in
            self?.isGeneratingFrame = false

            switch (status, cgImage) {
            case (.cancelled, _):
                break
            case (.failed, _), (.succeeded, nil):
                self?.showImageGenerationFailedAlert()
            case (.succeeded, let cgImage?):
                self?.shareImage(UIImage(cgImage: cgImage))
            }
        }
    }

    func shareImage(_ image: UIImage) {
        let shareController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(shareController, animated: true)
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

    func showImageGenerationFailedAlert() {
        let alertController = UIAlertController.imageGenerationFailed()
        present(alertController, animated: true)
    }
}
