import UIKit
import AVKit

class PlayerViewController: UIViewController, NavigationBarHiddenPreferring {

    var videoController: VideoController!

    private var selectedFramesController: SelectedFramesViewController?
    private var playbackController: PlaybackController?
    private lazy var timeFormatter = VideoTimeFormatter()

    @IBOutlet private var backgroundView: BlurredImageView!
    @IBOutlet private var playerView: ZoomingPlayerView!
    @IBOutlet private var loadingView: PlayerLoadingView!
    @IBOutlet private var titleView: PlayerTitleView!
    @IBOutlet private var controlsView: PlayerControlsView!

    private var isInitiallyReadyForPlayback = false

    private var isScrubbing: Bool {
        controlsView.timeSlider.isInteracting
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    var prefersNavigationBarHidden: Bool {
        true
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

        } else if let destination = segue.destination as? SelectedFramesViewController {
            selectedFramesController = destination
            selectedFramesController?.delegate = self
            selectedFramesController?.dataSource = videoController.video.flatMap(SelectedFramesDataSource.init)
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
        selectedFramesController?.clearSelection()
    }

    func stepBackward() {
        guard !isScrubbing else { return }
        playbackController?.step(byCount: -1)
        selectedFramesController?.clearSelection()
    }

    func stepForward() {
        guard !isScrubbing else { return }
        playbackController?.step(byCount: 1)
        selectedFramesController?.clearSelection()
    }

    @IBAction func addFrame() {
        guard !isScrubbing,
            // When the user spams the add button, older devices can run out of memory as
            // images are being requested more quickly than being generated. Limit to one.
            selectedFramesController?.isGeneratingFrames == false,
            let time = playbackController?.currentTime else { return }

        selectedFramesController?.insertFrame(for: time) { [weak self] result in
            guard self?.playbackController?.isPlaying == false else { return }
            self?.selectedFramesController?.selectFrame(at: result.index)
            self?.playbackController?.directlySeek(to: result.frame.definingTime)
        }
    }

    @IBAction func shareFrames() {
        guard !isScrubbing else { return }

        playbackController?.pause()

        if let times = selectedFramesController?.frames,
            !times.isEmpty {

            generateFramesAndShare(for: times)
        } else if let playbackController = playbackController {
            generateFramesAndShare(for: [playbackController.currentTime])
        }
    }

    @IBAction func scrub(_ sender: TimeSlider) {
        playbackController?.smoothlySeek(to: sender.time)
        selectedFramesController?.clearSelection()
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

    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateTracks tracks: [AVPlayerItemTrack]) {
        updateDetailLabels()
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

        controlsView.previousButton.repeatAction = { [weak self] in
            self?.stepBackward()
        }

        controlsView.nextButton.repeatAction = { [weak self] in
            self?.stepForward()
        }

        configureGestures()

        updatePlaybackStatus()
        updatePlayButton(withStatus: .paused)
        updateSlider(withDuration: .zero)
        updateSlider(withTime: .zero)
        updateTimeLabel(withTime: .zero)
        updateDetailLabels()
        updateLoadingProgress(with: nil)
        updatePreviewImage()
    }

    func configureGestures() {
        let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
        swipeRecognizer.direction = .down
        playerView.addGestureRecognizer(swipeRecognizer)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapRecognizer.require(toFail: playerView.doubleTapToZoomRecognizer)
        tapRecognizer.require(toFail: swipeRecognizer)
        playerView.addGestureRecognizer(tapRecognizer)
    }

    @objc func handleTap(sender: UIGestureRecognizer) {
        guard sender.state == .ended else { return }
        titleView.toggleHidden(animated: true)
        controlsView.toggleHidden(animated: true)
    }

    @objc func handleSwipeDown(sender: UIGestureRecognizer) {
        // Avoid dismissing when panning down Notification/Control Center.
        let nonInteractiveTopSpacing: CGFloat = 40

        guard sender.state == .ended,
            sender.location(in: playerView).y >= nonInteractiveTopSpacing else { return }

        done()
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

        controlsView.setControlsEnabled(isReadyToPlay)
    }

    func updatePreviewImage() {
        loadingView.imageView.isHidden = isInitiallyReadyForPlayback
    }

    func updateLoadingProgress(with progress: Float?) {
        loadingView.setProgress(progress, animated: true)
    }

    func updatePlayButton(withStatus status: AVPlayer.TimeControlStatus) {
        controlsView.playButton.setTimeControlStatus(status)
    }

    func updateDetailLabels() {
        let fps = videoController?.video?.frameRate
        let formattedDimensions = NumberFormatter().string(fromPixelDimensions: videoController.dimensions)
        let formattedFps = fps.flatMap { NumberFormatter.frameRateFormatter().string(fromFrameRate: $0) }

        titleView.setDetailLabels(for: formattedDimensions, frameRate: formattedFps)
    }

    func updateTimeLabel(withTime time: CMTime) {
        let showMilliseconds = playbackController?.isPlaying == false
        let formattedTime = timeFormatter.string(fromCurrentTime: time, includeMilliseconds: showMilliseconds)
        controlsView.timeLabel.text = formattedTime
    }

    func updateSlider(withTime time: CMTime) {
        guard !isScrubbing else { return }
        controlsView.timeSlider.time = time
    }

    func updateSlider(withDuration duration: CMTime) {
        controlsView.timeSlider.duration = duration
    }

    // MARK: Video Loading

    func loadPreviewImage() {
        let size = loadingView.imageView.bounds.size.scaledToScreen

        videoController.loadPreviewImage(with: size) { [weak self] image, _ in
            guard let image = image else { return }
            self?.loadingView.imageView.image = image
            // Use same image for background (ignoring different size/content mode as it's blurred).
            self?.backgroundView.imageView.image = image
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
        selectedFramesController?.dataSource = SelectedFramesDataSource(video: video)

        playbackController = PlaybackController(playerItem: AVPlayerItem(asset: video))
        playbackController?.delegate = self
        playerView.player = playbackController?.player

        playbackController?.play()
    }

    // MARK: Image Generation

    // TODO: Coordinate alerts: playback can fail while metadata view or export is showing.
    // TODO: Extract export UI task as class (presents, glue code, manages state, cleans up, ...)

    func generateFramesAndShare(for times: [CMTime]) {
        let progressController = ProgressViewController.instantiateFromStoryboard()

        let progress = videoController.generateAndExportFrames(for: times) { [weak self] result in
            progressController.dismiss(animated: false) {
                self?.handleFrameGenerationResult(result)
            }
        }

        guard progress != nil else { return }

        progressController.progress = progress
        present(progressController, animated: true)
    }

    func handleFrameGenerationResult(_ result: FrameExporter.Result) {
        let completeFrameExport = { [weak self] in
            self?.videoController.deleteFrames(for: result)
        }

        guard !result.anyCancelled, !result.anyFailed else {
            completeFrameExport()
            if result.anyFailed {
                presentAlert(.imageGenerationFailed())
            }
            return
        }

        let shareController = UIActivityViewController(activityItems: result.urls, applicationActivities: nil)

        shareController.completionWithItemsHandler = { _, _, _, _ in
           completeFrameExport()
        }

        present(shareController, animated: true)
    }
}

// MARK: - SelectedFramesViewControllerDelegate

extension PlayerViewController: SelectedFramesViewControllerDelegate {

    func controller(_ controller: SelectedFramesViewController, didSelectFrameAt time: CMTime) {
        playbackController?.directlySeek(to: time)
    }
}

// MARK: - ZoomAnimatable

extension PlayerViewController: ZoomAnimatable {

    func zoomAnimatorAnimationWillBegin(_ animator: ZoomAnimator) {
        playerView.isHidden = true
        loadingView.isHidden = true
        controlsView.isHidden = true  
        titleView.isHidden = true
    }

    func zoomAnimatorAnimationDidEnd(_ animator: ZoomAnimator) {
        playerView.isHidden = false
        loadingView.isHidden = false
        controlsView.setHidden(false, animated: true, duration: 0.2)
        titleView.setHidden(false, animated: true, duration: 0.2)
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
