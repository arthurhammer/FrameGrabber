import UIKit
import AVFoundation
import Combine

class EditorViewController: UIViewController {

    var videoController: VideoController!
    var transitionController: ZoomTransitionController?

    // MARK: Private Properties

    private lazy var playbackController = PlaybackController()
    private lazy var timeFormatter = VideoTimeFormatter()
    private lazy var bindings = Set<AnyCancellable>()

    @IBOutlet private var titleView: EditorTitleView!
    @IBOutlet private var toolbar: EditorToolbar!
    @IBOutlet private var zoomingPlayerView: ZoomingPlayerView!
    @IBOutlet private var scrubbingIndicator: ScrubbingIndicatorView!
    @IBOutlet private var progressView: ProgressView!

    private var isScrubbing: Bool {
        toolbar.timeSlider.isTracking
    }

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        loadPreviewImage()
        loadVideo()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        videoController.cancelFrameExport()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? UINavigationController,
            let controller = destination.topViewController as? VideoDetailViewController {

            prepareForVideoDetailSegue(with: controller)
        }
    }

    private func prepareForVideoDetailSegue(with controller: VideoDetailViewController) {
        playbackController.pause()
        controller.videoController = VideoController(asset: videoController.asset, video: videoController.video)
    }
}

// MARK: - Private

private extension EditorViewController {

    // MARK: Actions

    func done() {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func playOrPause() {
        guard !isScrubbing else { return }
        playbackController.playOrPause()
    }

    @IBAction func stepBackward() {
        guard !isScrubbing else { return }
        playbackController.step(byCount: -1)
    }

    @IBAction func stepForward() {
        guard !isScrubbing else { return }
        playbackController.step(byCount: 1)
    }

    @IBAction func shareFrames() {
        guard !isScrubbing else { return }

        playbackController.pause()
        generateFramesAndShare(for: [playbackController.currentTime])
    }

    @IBAction func scrub(_ sender: TimeSlider) {
        playbackController.smoothlySeek(to: sender.time)
    }

    // MARK: Configuring

    func configureViews() {
        zoomingPlayerView.clipsToBounds = false
        zoomingPlayerView.player = playbackController.player
        zoomingPlayerView.posterImage = videoController.previewImage

        scrubbingIndicator.configure(for: toolbar.timeSlider)

        configureNavigationBar()
        configureGestures()
        bindPlayer()
    }

    func configureNavigationBar() {
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.applyToolbarShadow()
        toolbar.applyToolbarShadow()
    }

    func configureGestures() {
        let slideToPopRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleSlideToPopPan))
        zoomingPlayerView.addGestureRecognizer(slideToPopRecognizer)
    }

    @objc func handleSlideToPopPan(_ gesture: UIPanGestureRecognizer) {
        let hasVideoOrPoster = zoomingPlayerView.playerView.bounds.size != .zero

        guard !isScrubbing,
            hasVideoOrPoster else { return }

        transitionController?.handleSlideToPopGesture(gesture, performTransition: {
            done()
        })
    }

    func presentOnTop(_ viewController: UIViewController, animated: Bool = true) {
        let presenter = navigationController ?? presentedViewController ?? self
        presenter.present(viewController, animated: animated)
    }

    func bindPlayer() {
        playbackController
            .$status
            .map { $0 == .readyToPlay }
            .sink { [weak self] in
                self?.titleView.setEnabled($0)
                self?.toolbar.setEnabled($0)
                self?.navigationItem.rightBarButtonItem?.isEnabled = $0
            }
            .store(in: &bindings)

        playbackController
            .$status
            .filter { $0 == .failed }
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.presentOnTop(UIAlertController.playbackFailed())
            }
            .store(in: &bindings)

        playbackController
            .$duration
            .assignWeak(to: \.duration, on: toolbar.timeSlider)
            .store(in: &bindings)

        playbackController
            .$currentTime
            .sink { [weak self] in
                self?.updateTimeLabel(withTime: $0)
                self?.toolbar.timeSlider.setTime($0, animated: true)
            }
            .store(in: &bindings)

        playbackController
            .$timeControlStatus
            .sink { [weak self] in
                self?.toolbar.playButton.setTimeControlStatus($0)
            }
            .store(in: &bindings)
    }

    func updateTimeLabel(withTime time: CMTime) {
        let showMilliseconds = !playbackController.isPlaying
        let formattedTime = timeFormatter.string(fromCurrentTime: time, includeMilliseconds: showMilliseconds)
        titleView.setFormattedTime(formattedTime, animated: true)
    }

    // MARK: Loading Videos

    func loadPreviewImage() {
        let size = zoomingPlayerView.bounds.size.scaledToScreen

        videoController.loadPreviewImage(with: size) { [weak self] image, _ in
            guard let image = image else { return }
            self?.zoomingPlayerView.posterImage = image
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
            playbackController.asset = video
            playbackController.play()
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
        case .cancelled, .progressed:
            break
        case .failed:
            presentOnTop(UIAlertController.frameExportFailed())
        case .succeeded(let urls):
            share(urls: urls)
        }

        status.feedback.flatMap(feedbackGenerator.notificationOccurred)
    }

    func share(urls: [URL]) {
        let shareController = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        shareController.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.videoController.deleteExportedFrames()
        }
        presentOnTop(shareController)
    }

    // MARK: Showing Progress

    enum Activity {
        case download
        case export

        var title: String {
            switch self {
            case .download: return UserText.editoriCloudProgress
            case .export: return UserText.editorExportProgress
            }
        }
    }

    func showProgress(_ show: Bool, forActivity activity: Activity, value: ProgressView.Progress? = nil, animated: Bool = true, completion: (() -> ())? = nil) {
        view.isUserInteractionEnabled = !show  // todo

        let localLoadMightTakeAWhile = (activity == .download) && (value == .determinate(0))
        progressView.showDelay = localLoadMightTakeAWhile ? 0.3 : 0.1

        progressView.titleLabel.text = activity.title
        if show {
            progressView.show(in: zoomingPlayerView, animated: animated, completion: completion)
        } else {
            progressView.hide(animated: animated, completion: completion)
        }

        if let value = value {
            progressView.setProgress(value, animated: animated)
        }
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
        zoomingPlayerView.playerView
    }
}

private extension FrameExport.Status {
    var feedback: UINotificationFeedbackGenerator.FeedbackType? {
        switch self {
        case .cancelled: return .warning
        case .failed: return .error
        case .progressed: return nil
        case .succeeded: return .success
        }
    }
}
