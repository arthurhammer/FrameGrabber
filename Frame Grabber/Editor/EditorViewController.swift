import UIKit
import AVKit

class EditorViewController: UIViewController {

    var videoController: VideoController!
    var transitionController: ZoomTransitionController?

    private var playbackController: PlaybackController?
    private lazy var timeFormatter = VideoTimeFormatter()

    @IBOutlet private var progressView: ProgressView!
    @IBOutlet private var playerView: ZoomingPlayerView!
    @IBOutlet private var toolbar: EditorToolbar!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var timeLabel: UILabel!

    private var isScrubbing: Bool {
        toolbar.timeSlider.isTracking
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        videoController.cancelFrameExport()
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

    func presentOnTop(_ viewController: UIViewController, animated: Bool = true) {
        let presenter = navigationController ?? presentedViewController ?? self
        presenter.present(viewController, animated: animated)
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
        presentOnTop(UIAlertController.playbackFailed())
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

// MARK: - Private

private extension EditorViewController {

    func configureViews() {
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
    }

    private func configureGestures() {
        let slideToPopRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleSlideToPopPan))
        playerView.addGestureRecognizer(slideToPopRecognizer)
    }

    @objc private func handleSlideToPopPan(_ gesture: UIPanGestureRecognizer) {
        let hasVideoOrPoster = playerView.playerView.bounds.size != .zero
        guard !isScrubbing, hasVideoOrPoster else { return }

        transitionController?.handleSlideToPopGesture(gesture, performTransition: {
            done()
        })
    }

    // MARK: Updating Player UI

    func updatePlaybackStatus() {
        let isReadyToPlay = playbackController?.isReadyToPlay ?? false
        toolbar.setControlsEnabled(isReadyToPlay)
        navigationItem.rightBarButtonItem?.isEnabled = isReadyToPlay
        titleLabel.isEnabled = isReadyToPlay
        timeLabel.isEnabled = isReadyToPlay
    }

    func updatePlayButton(withStatus status: AVPlayer.TimeControlStatus) {
        toolbar.playButton.setTimeControlStatus(status)
    }

    func updateTimeLabel(withTime time: CMTime) {
        let showMilliseconds = playbackController?.isPlaying == false
        let formattedTime = timeFormatter.string(fromCurrentTime: time, includeMilliseconds: showMilliseconds)

        UIView.animate(withDuration: 0.15, delay: 0, options: .beginFromCurrentState, animations: {
            self.timeLabel.text = formattedTime
            self.timeLabel.superview?.layoutIfNeeded()
        }, completion: nil)
    }

    func updateSlider(withTime time: CMTime) {
        guard !isScrubbing else { return }
        toolbar.timeSlider.setTime(time, animated: true)
    }

    func updateSlider(withDuration duration: CMTime) {
        toolbar.timeSlider.duration = duration
    }

    // MARK: Showing Progress

    enum Activity {
        case download
        case export

        var title: String {
            switch self {
            case .download: return NSLocalizedString("progress.title.icloud", value: "Downloading…", comment: "iCloud download progress title.")
            case .export: return NSLocalizedString("progress.title.frameExport", value: "Exporting…", comment: "Frame generation progress title.")
            }
        }
    }

    func showProgress(_ show: Bool, forActivity activity: Activity, value: ProgressView.Progress? = nil, animated: Bool = true, completion: (() -> ())? = nil) {
        view.isUserInteractionEnabled = !show  // todo

        let localLoadMightTakeAWhile = (activity == .download) && (value == .determinate(0))
        progressView.showDelay = localLoadMightTakeAWhile ? 0.3 : 0.1

        progressView.titleLabel.text = activity.title
        if show {
            progressView.show(in: playerView, animated: animated, completion: completion)
        } else {
            progressView.hide(animated: animated, completion: completion)
        }

        if let value = value {
            progressView.setProgress(value, animated: animated)
        }
    }

    // MARK: Loading Videos

    func loadPreviewImage() {
        let size = playerView.bounds.size.scaledToScreen

        videoController.loadPreviewImage(with: size) { [weak self] image, _ in
            guard let image = image else { return }
            self?.playerView.posterImageView.image = image
        }
    }

    func loadVideo() {
        showProgress(true, forActivity: .download, value: .determinate(0))

        videoController.loadVideo(progressHandler: { [weak self] progress in
            self?.progressView.setProgress(.determinate(Float(progress)), animated: true)
        }, completionHandler: { [weak self] result in
            self?.showProgress(false, forActivity: .download, value: .determinate(1))
            self?.handleVideoLoadingResult(result)
        })
    }

    func handleVideoLoadingResult(_ result: VideoController.VideoResult) {
        switch result {

        case .failure(let error):
            guard !error.isCocoaCancelledError else { return }
            presentOnTop(UIAlertController.videoLoadingFailed())

        case .success(let video):
            playbackController = PlaybackController(playerItem: AVPlayerItem(asset: video))
            playbackController?.delegate = self
            playerView.player = playbackController?.player
            playbackController?.play()
        }
    }

    // MARK: Generating Images

    func generateFramesAndShare(for times: [CMTime]) {
        showProgress(true, forActivity: .export, value: .indeterminate)

        videoController.generateAndExportFrames(for: times) { [weak self] status in
            self?.showProgress(false, forActivity: .export) {
                self?.handleFrameGenerationResult(status)
            }
        }
    }

    func handleFrameGenerationResult(_ status: FrameExport.Status) {
        let feedbackGenerator = UINotificationFeedbackGenerator()

        switch status {

        case .failed:
            feedbackGenerator.notificationOccurred(.error)
            presentOnTop(UIAlertController.imageGenerationFailed())

        case .cancelled:
            feedbackGenerator.notificationOccurred(.warning)

        case .progressed:
            break

        case .succeeded(let urls):
            feedbackGenerator.notificationOccurred(.success)
            share(urls: urls)
        }
    }

    func share(urls: [URL]) {
        let shareController = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        shareController.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.videoController.deleteExportedFrames()
        }
        presentOnTop(shareController)
    }
}

// MARK: - ZoomTransitionDelegate

extension EditorViewController: ZoomTransitionDelegate {

    func zoomTransitionWillBegin(_ transition: ZoomTransition) {
        guard transition.type == .pop else { return }

        let backgroundColor = view.backgroundColor

        transition.animate(alongsideTransition: { [weak self] _ in
            guard let self = self else { return }
            self.view.backgroundColor = .clear
            self.progressView.alpha = 0
            self.toolbar.alpha = 0
            self.toolbar.transform = CGAffineTransform.identity.translatedBy(x: 0, y: self.toolbar.bounds.height * 1.5)
        }, completion: { [weak self] _ in
            // Animation interpolates dynamic to fixed color. Restore dynamic color.
            self?.view.backgroundColor = backgroundColor
        })
    }

    func zoomTransitionView(_ transition: ZoomTransition) -> UIView? {
        playerView.playerView
    }
}
