import UIKit
import AVKit

class EditorViewController: UIViewController {

    var videoController: VideoController!
    var transitionController: ZoomTransitionController?

    private var playbackController: PlaybackController?
    private lazy var timeFormatter = VideoTimeFormatter()

    @IBOutlet private var playerView: ZoomingPlayerView!
    @IBOutlet private var loadingView: EditorLoadingView!
    @IBOutlet private var toolbar: EditorToolbar!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var timeLabel: UILabel!

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.shadowImage = UIImage()
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

private extension EditorViewController {

    func done() {
        // (todo: Move into coordinator/delegate?)
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

extension EditorViewController: PlaybackControllerDelegate {

    func player(_ player: AVPlayer, didUpdateStatus status: AVPlayer.Status) {
        guard status != .failed  else { return handlePlaybackError() }
        updatePlaybackStatus()
    }

    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateStatus status: AVPlayerItem.Status) {
        guard status != .failed else { return handlePlaybackError() }
        updatePlaybackStatus()
    }

    private func handlePlaybackError() {
        (presentedViewController ?? self).presentAlert(.playbackFailed())
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

extension EditorViewController: ZoomingPlayerViewDelegate {

    func playerView(_ playerView: ZoomingPlayerView, didUpdateReadyForDisplay ready: Bool) {
        updatePlaybackStatus()
    }
}

// MARK: - Private

private extension EditorViewController {

    func configureViews() {
        playerView.delegate = self
        playerView.clipsToBounds = false

        timeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)

        // todo: Navigation controller/delegate should handle this.
        navigationController?.navigationBar.shadowImage = nil
        navigationController?.navigationBar.applyToolbarShadow()
        toolbar.applyToolbarShadow()

        toolbar.previousButton.repeatAction = { [weak self] in
            self?.stepBackward()
        }

        toolbar.nextButton.repeatAction = { [weak self] in
            self?.stepForward()
        }

        configureGestures()

        updatePlaybackStatus()
        updatePlayButton(withStatus: .paused)
        updateSlider(withDuration: .zero)
        updateSlider(withTime: .zero)
        updateTimeLabel(withTime: .zero)
        updateLoadingProgress(with: nil)
    }

    private func configureGestures() {
        let slideToPopRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleSlideToPopPan))
        playerView.addGestureRecognizer(slideToPopRecognizer)
    }

    @objc private func handleSlideToPopPan(_ gesture: UIPanGestureRecognizer) {
        guard !isScrubbing else { return }
        
        transitionController?.handleSlideToPopGesture(gesture, performTransition: {
            done()
        })
    }

    // MARK: Sync Player UI

    func updatePlaybackStatus() {
        let isReadyToPlay = playbackController?.isReadyToPlay ?? false
        toolbar.setControlsEnabled(isReadyToPlay)
        navigationItem.rightBarButtonItem?.isEnabled = isReadyToPlay
        titleLabel.isEnabled = isReadyToPlay
        timeLabel.isEnabled = isReadyToPlay
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
        let size = playerView.bounds.size.scaledToScreen

        videoController.loadPreviewImage(with: size) { [weak self] image, _ in
            guard let image = image else { return }
            self?.playerView.posterImageView.image = image
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
                (self?.presentedViewController ?? self)?.presentAlert(.videoLoadingFailed())
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
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.prepare()

        videoController.generateAndExportFrames(for: times, progressHandler: { completed, total in }, completionHandler: { [weak self] result in
            self?.view.isUserInteractionEnabled = true
            self?.handleFrameGenerationResult(result, withFeedbackGenerator: feedbackGenerator)
        })
    }

    func handleFrameGenerationResult(_ result: FrameExporter.Result, withFeedbackGenerator feedbackGenerator: UINotificationFeedbackGenerator?) {
        switch result {

        case .failed:
            feedbackGenerator?.notificationOccurred(.error)
            presentAlert(.imageGenerationFailed())

        case .cancelled:
            feedbackGenerator?.notificationOccurred(.warning)

        case .succeeded(let urls):
            feedbackGenerator?.notificationOccurred(.success)
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

// MARK: - ZoomTransitionDelegate

extension EditorViewController: ZoomTransitionDelegate {

    func zoomTransitionWillBegin(_ transition: ZoomTransition) {
        guard transition.type == .pop else { return }

        let backgroundColor = view.backgroundColor

        loadingView.alpha = 0  // (Don't animate.)

        transition.animate(alongsideTransition: { [weak self] _ in
            guard let self = self else { return }
            self.view.backgroundColor = .clear
            self.toolbar.alpha = 0
            self.toolbar.transform = CGAffineTransform.identity.translatedBy(x: 0, y: self.toolbar.bounds.height * 1.5)
        }, completion: { [weak self] _ in
            // Animation interpolates dynamic to fixed color. Restore dynamic color.
            self?.view.backgroundColor = backgroundColor
            self?.loadingView.alpha = 1
        })
    }

    func zoomTransitionView(_ transition: ZoomTransition) -> UIView? {
        playerView.playerView
    }
}
