import UIKit
import AVKit

class PlayerViewController: UIViewController {

    var videoManager: VideoManager!
    var settings = UserDefaults.standard

    private var playbackController: PlaybackController?

    private lazy var timeFormatter = VideoTimeFormatter()
    private lazy var dimensionFormatter = VideoDimensionFormatter()

    @IBOutlet private var backgroundView: BlurredImageView!
    @IBOutlet private var playerView: ZoomingPlayerView!
    @IBOutlet private var loadingView: PlayerLoadingView!
    @IBOutlet private var overlay: PlayerOverlayView!

    private var isScrubbing: Bool {
        return overlay.controlsView.timeSlider.isInteracting
    }

    private var isSeeking: Bool {
        return playbackController?.isSeeking ?? false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func preferredScreenEdgesDeferringSystemGestures() -> UIRectEdge {
        // Control center can interfere with repeating buttons
        return .bottom
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
        videoManager.cancelAllRequests()
        playbackController?.pause()
        dismiss(animated: true)
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
        generateFrameAndShare(from: item.asset, at: item.currentTime())
    }

    @IBAction func scrub(_ sender: TimeSlider) {
        playbackController?.seeker.smoothlySeek(to: sender.time)
        // When scrubbing, display slider time instead of player time.
        updateViews(withTime: sender.time)
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

    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateDuration duration: CMTime) {
        updateSlider(withDuration: duration)
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
        playerView.delegate = self

        overlay.controlsView.previousButton.repeatAction = { [weak self] in
            self?.stepBackward()
        }

        overlay.controlsView.nextButton.repeatAction = { [weak self] in
            self?.stepForward()
        }

        configureGestures()

        updatePlayButton(withStatus: .paused)
        updateSlider(withDuration: .zero)
        updateViews(withTime: .zero)
        updateDimensionsLabel()
        updateViewsForPlayer()
    }

    func configureGestures() {
        let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
        swipeRecognizer.direction = .down
        playerView.addGestureRecognizer(swipeRecognizer)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        // zooming view installs its own double tap recognizer
        tapRecognizer.require(toFail: playerView.doubleTapToZoomRecognizer)
        tapRecognizer.require(toFail: swipeRecognizer)
        playerView.addGestureRecognizer(tapRecognizer)
    }

    @objc func handleTap(sender: UIGestureRecognizer) {
        guard sender.state == .ended else { return }
        overlay.toggleHidden(animated: true)
    }

    @objc func handleSwipeDown(sender: UIGestureRecognizer) {
        guard sender.state == .ended else { return }
        done()
    }

    // MARK: Sync Player UI

    var shouldDisableControls: Bool {
        guard let playbackController = playbackController else { return true }

        return !playbackController.isReadyToPlay
            || videoManager.isGeneratingFrame
    }

    func updatePlayerControlsEnabled() {
        overlay.controlsView.setControlsEnabled(!shouldDisableControls)
    }

    func updateViewsForPlayer() {
        updatePlayerControlsEnabled()
        updatePreviewImage()
    }

    func updatePreviewImage() {
        let isReady = (playbackController?.isReadyToPlay ?? false) && playerView.isReadyForDisplay
        let hasPreview = loadingView.previewImageView.image != nil

        loadingView.previewImageView.isHidden = !hasPreview || isReady

        if isReady {
            videoManager.imageRequest?.cancel()
        }
    }

    func updateCloudDownloadProgressView(with progress: Float? = nil) {
        loadingView.progressView.setProgress(progress ?? 0, animated: true)
        loadingView.progressView.isHidden = progress == nil
        loadingView.titleLabel.isHidden = progress == nil
    }

    func updatePlayButton(withStatus status: AVPlayerTimeControlStatus) {
        overlay.controlsView.playButton.setTimeControlStatus(status)
    }

    func updateDimensionsLabel() {
        let size = CGSize(width: videoManager.asset.pixelWidth, height: videoManager.asset.pixelHeight)
        let dimensions = dimensionFormatter.string(from: size)
        overlay.titleView.detailLabel.text = dimensions
    }

    func updateViews(withTime time: CMTime) {
        updateSlider(withTime: time)
        updateTimeLabel(withTime: time)
    }

    func updateTimeLabel(withTime time: CMTime) {
        let showMilliseconds = playbackController?.isPlaying == false
        let formattedTime = timeFormatter.string(fromCurrentTime: time, includeMilliseconds: showMilliseconds)
        overlay.controlsView.timeLabel.text = formattedTime
    }

    func updateSlider(withTime time: CMTime) {
        guard !isScrubbing && !isSeeking else { return }
        overlay.controlsView.timeSlider.time = time
    }

    func updateSlider(withDuration duration: CMTime) {
        // Time is `.indefinite` when item is not ready to play
        let duration = (duration == .indefinite) ? .zero : duration
        overlay.controlsView.timeSlider.duration = duration
    }

    // MARK: Video Loading

    func loadVideo() {
        loadPreviewImage()
        loadPlayerItem()
    }

    func loadPreviewImage() {
        let size = loadingView.previewImageView.bounds.size.scaledToScreen
        let config = ImageConfig(size: size, mode: .aspectFit, options: .default())

        videoManager.posterImage(with: config) { [weak self] image, _ in
            guard let image = image else { return }
            self?.loadingView.previewImageView.image = image
            // use same image for background (ignoring different size/content mode as it's blurred)
            self?.backgroundView.imageView.image = image
            self?.updatePreviewImage()
        }
    }

    func loadPlayerItem() {
        videoManager.downloadingPlayerItem(progressHandler: { [weak self] progress in
            self?.updateCloudDownloadProgressView(with: Float(progress))

        }, resultHandler: { [weak self] playerItem, info in
            self?.updateCloudDownloadProgressView()

            guard !info.isCancelled else { return }

            if let playerItem = playerItem {
                self?.configurePlayer(with: playerItem)
            } else {
                self?.showVideoLoadingFailedAlertAndDismiss()
            }
        })

        updateCloudDownloadProgressView()
    }

    func configurePlayer(with playerItem: AVPlayerItem) {
        playbackController = PlaybackController(playerItem: playerItem)
        playbackController?.delegate = self
        playerView.player = playbackController?.player

        playbackController?.play()
    }

    // MARK: Image Generation

    func generateFrameAndShare(from asset: AVAsset, at time: CMTime) {
        videoManager.frame(for: asset, at: time) { [weak self] result in
            self?.updatePlayerControlsEnabled()

            switch (result) {
            case .cancelled:
                break
            case .failed:
                self?.showImageGenerationFailedAlert()
            case .succeeded(let image, _, _):
                self?.shareImage(image)
            }
        }

        updatePlayerControlsEnabled()
    }

    func shareImage(_ image: UIImage) {
        // If creation fails, share plain image without metadata.
        if settings.includeMetadata,
            let metadataImage = videoManager.jpgImageDataByAddingAssetMetadata(to: image, quality: 1) {

            shareItem(metadataImage)
        } else {
            shareItem(image)
        }
    }

    func shareItem(_ item: Any) {
        let shareController = UIActivityViewController(activityItems: [item], applicationActivities: nil)
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
