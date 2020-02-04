import UIKit
import AVKit

class PlayerViewController: UIViewController {

    var videoController: VideoController!

    private var playbackController: PlaybackController?
    private lazy var timeFormatter = VideoTimeFormatter()

    @IBOutlet private var playerView: ZoomingPlayerView!
    @IBOutlet private var loadingView: PlayerLoadingView!
    @IBOutlet private var toolbar: PlayerControlsView!
    @IBOutlet private var timeLabel: UILabel!

    private var isInitiallyReadyForPlayback = false

    private var isScrubbing: Bool {
        toolbar.timeSlider.isTracking
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        loadPreviewImage()
        loadVideo()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? UINavigationController,
            let controller = destination.topViewController as? VideoDetailViewController {

            playbackController?.pause()
            controller.videoController = VideoController(asset: videoController.asset, video: videoController.video)
        }
    }
}

// MARK: - Actions

private extension PlayerViewController {

    @IBAction func done() {
        videoController.cancelAllRequests()
        playbackController?.pause()

        // TODO: A delegate/the coordinator should handle this.
        navigationController?.popViewController(animated: true)
    }

    @IBAction func playOrPause() {
        guard !isScrubbing else { return }
        playbackController?.playOrPause()
    }

    func stepBackward() {
        guard !isScrubbing else { return }
        playbackController?.step(byCount: -1)
    }

    func stepForward() {
        guard !isScrubbing else { return }
        playbackController?.step(byCount: 1)
    }

    @IBAction func shareFrames() {
        guard !isScrubbing,
            let playbackController = playbackController else { return }

        playbackController.pause()
        generateFramesAndShare(for: [playbackController.currentTime])
    }

    @IBAction func scrub(_ sender: TimeSlider) {
        playbackController?.smoothlySeek(to: sender.time)
    }
}

// MARK: - PlaybackControllerDelegate

extension PlayerViewController: PlaybackControllerDelegate {

    func player(_ player: AVPlayer, didUpdateStatus status: AVPlayer.Status) {
        guard status != .failed  else { return handlePlaybackError() }
        updatePlaybackStatus()
    }

    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateStatus status: AVPlayerItem.Status) {
        guard status != .failed else { return handlePlaybackError() }
        updatePlaybackStatus()
    }

    private func handlePlaybackError() {
        // Dismiss detail view if necessary, show alert, on "OK" dismiss.
        dismiss(animated: true) {
            self.presentAlert(.playbackFailed { _ in
                self.done()
            })
        }
    }

    func player(_ player: AVPlayer, didPeriodicUpdateAtTime time: CMTime) {
        updateSlider(withTime: time)
        updateTimeLabel(withTime: time)
    }

    func player(_ player: AVPlayer, didUpdateTimeControlStatus status: AVPlayer.TimeControlStatus) {
        updatePlayButton(withStatus: status)
    }

    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateDuration duration: CMTime) {
        updateSlider(withDuration: duration)
    }
}

// MARK: - ZoomingPlayerViewDelegate

extension PlayerViewController: ZoomingPlayerViewDelegate {

    func playerView(_ playerView: ZoomingPlayerView, didUpdateReadyForDisplay ready: Bool) {
        updatePlaybackStatus()
    }
}

// MARK: - Private

private extension PlayerViewController {

    func configureViews() {
        playerView.delegate = self
        playerView.clipsToBounds = false

        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)

        // TODO: Navigation controller/delegate should handle this
        if let navBar = navigationController?.navigationBar {
            navBar.shadowImage = UIImage()
            navBar.layer.shadowColor = UIColor.black.cgColor
            navBar.layer.shadowOffset = .zero
            navBar.layer.shadowOpacity = 0.1
            navBar.layer.shadowRadius = 12

            toolbar.layer.shadowColor = navBar.layer.shadowColor
            toolbar.layer.shadowOffset = navBar.layer.shadowOffset
            toolbar.layer.shadowOpacity = navBar.layer.shadowOpacity
            toolbar.layer.shadowRadius = navBar.layer.shadowRadius
        }

        toolbar.previousButton.repeatAction = { [weak self] in
            self?.stepBackward()
        }

        toolbar.nextButton.repeatAction = { [weak self] in
            self?.stepForward()
        }

        updatePlaybackStatus()
        updatePlayButton(withStatus: .paused)
        updateSlider(withDuration: .zero)
        updateSlider(withTime: .zero)
        updateTimeLabel(withTime: .zero)
        updateLoadingProgress(with: nil)
        updatePreviewImage()
    }

    // MARK: Sync Player UI

    func updatePlaybackStatus() {
        let isReadyToPlay = playbackController?.isReadyToPlay ?? false
        let isReadyToDisplay = playerView.isReadyForDisplay

        // All player, item and view will reset their readiness on loops. Capture when
        // all have been ready at least once. (Later states not considered.)
        if isReadyToPlay && isReadyToDisplay {
            isInitiallyReadyForPlayback = true
            updatePreviewImage()
        }

        toolbar.setControlsEnabled(isReadyToPlay)
    }

    func updatePreviewImage() {
        loadingView.imageView.isHidden = isInitiallyReadyForPlayback
    }

    func updateLoadingProgress(with progress: Float?) {
        loadingView.setProgress(progress, animated: true)
    }

    func updatePlayButton(withStatus status: AVPlayer.TimeControlStatus) {
        toolbar.playButton.setTimeControlStatus(status)
    }

    func updateTimeLabel(withTime time: CMTime) {
        let showMilliseconds = playbackController?.isPlaying == false
        let formattedTime = timeFormatter.string(fromCurrentTime: time, includeMilliseconds: showMilliseconds)
        timeLabel.text = formattedTime
    }

    func updateSlider(withTime time: CMTime) {
        guard !isScrubbing else { return }
        toolbar.timeSlider.setTime(time, animated: true)
    }

    func updateSlider(withDuration duration: CMTime) {
        toolbar.timeSlider.duration = duration
    }

    // MARK: Video Loading

    func loadPreviewImage() {
        let size = loadingView.imageView.bounds.size.scaledToScreen

        videoController.loadPreviewImage(with: size) { [weak self] image, _ in
            guard let image = image else { return }
            self?.loadingView.imageView.image = image
            self?.updatePreviewImage()
        }
    }

    func loadVideo() {
        videoController.loadVideo(progressHandler: { [weak self] progress in

            self?.updateLoadingProgress(with: Float(progress))

        }, completionHandler: { [weak self] video, info in

            self?.updateLoadingProgress(with: nil)

            guard !info.isCancelled else { return }

            if let video = video {
                self?.configurePlayer(with: video)
            } else {
                self?.presentAlert(.videoLoadingFailed { _ in self?.done() })
            }
        })
    }

    func configurePlayer(with video: AVAsset) {
        playbackController = PlaybackController(playerItem: AVPlayerItem(asset: video))
        playbackController?.delegate = self
        playerView.player = playbackController?.player

        playbackController?.play()
    }

    // MARK: Image Generation

    func generateFramesAndShare(for times: [CMTime]) {
        view.isUserInteractionEnabled = false

        videoController.generateAndExportFrames(for: times, progressHandler: { completed, total in }, completionHandler: { [weak self] result in
            self?.view.isUserInteractionEnabled = true
            self?.handleFrameGenerationResult(result)
        })
    }

    func handleFrameGenerationResult(_ result: FrameExporter.Result) {
        switch result {
        case .failed:
            presentAlert(.imageGenerationFailed())
        case .cancelled:
            break
        case .succeeded(let urls):
            share(urls: urls)
        }
    }

    func share(urls: [URL]) {
        let shareController = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        shareController.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.videoController.deleteFrames(for: urls)
        }
        present(shareController, animated: true)
    }
}

// MARK: - ZoomAnimatable

extension PlayerViewController: ZoomAnimatable {

    func zoomAnimatorAnimationWillBegin(_ animator: ZoomAnimator) {
        playerView.isHidden = true
        loadingView.isHidden = true
    }

    func zoomAnimatorAnimationDidEnd(_ animator: ZoomAnimator) {
        playerView.isHidden = false
        loadingView.isHidden = false
        updatePreviewImage()
    }

    func zoomAnimatorImage(_ animator: ZoomAnimator) -> UIImage? {
        loadingView.imageView.image
    }

    func zoomAnimator(_ animator: ZoomAnimator, imageFrameInView view: UIView) -> CGRect? {
        let videoFrame = playerView.zoomedVideoFrame

        // If ready animate from video position (possibly zoomed, scrolled), otherwise
        // from preview image (centered, aspect fitted).
        if videoFrame != .zero {
            return playerView.superview?.convert(videoFrame, to: view)
        } else {
            return loadingView.convert(loadingImageFrame, to: view)
        }
    }

    /// The aspect fitted size the preview image occupies in the image view.
    private var loadingImageFrame: CGRect {
        let imageSize = loadingView.imageView.image?.size
            ?? videoController.asset.dimensions

        return AVMakeRect(aspectRatio: imageSize, insideRect: loadingView.imageView.frame)
    }
}
