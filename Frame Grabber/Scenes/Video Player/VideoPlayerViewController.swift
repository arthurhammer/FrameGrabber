import UIKit
import AVKit

// Bug: dimensions label hides for a sec. why?

// todo: error button + action
// todo: preview image
// todo: implement proper status controller
// todo: test all states: error, icloud, ...
// todo: settings

class VideoPlayerViewController: UIViewController {

    var video: Video! {
        didSet {
            guard let video = video else { fatalError("Video is required") }
            // TODO: status view controller image needs to be reset (otherwise might show old image)
            // BUT: hes not loaded yet

            player = Player(video: video)
            player!.delegate = self  // TODO: how does delegate even get all status updates when player already starts loading!?
            loadPreviewImage(for: video)  // TODO

            updateViews()
        }
    }

    func loadPreviewImage(for video: Video) {
        let size = view.frame.size.scaledToScreen

        previewImageRequest = ImageRequest(asset: video.asset, targetSize: size, contentMode: .aspectFit, options: .videoPreview()) { [weak self] image, _ in
            self?.updateViews()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        updateViews()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? AVPlayerViewController {
            playerViewController = controller
        } else if let controller = segue.destination as? VideoPlayerStatusControllerTMP {
            statusViewController = controller
        }
    }

    @IBAction func done() {
        // Avoid glitches during dismissal
        player?.pause()
        dismiss(animated: true)
    }

    @IBAction func stepForward() {
        player?.stepForward()
        testfunc(1.1)

        // TODO
    }

    func testfunc(_ scale: CGFloat) {
        UIView.animate(withDuration: 0.08, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
            self.frameControlsView.currentTimeLabel.transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
        }, completion: { _ in
            UIView.animate(withDuration: 0.08, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
                self.frameControlsView.currentTimeLabel.transform = .identity
            })
        })
    }

    @IBAction func stepBackward() {
        player?.stepBackward()
        testfunc(0.9)
    }

    @IBAction func shareVideoFrame() {
        guard let player = player,
            let playerItem = player.playerStack?.currentItem else { return }

        player.pause()

        let imageGenerator = AVAssetImageGenerator(asset: playerItem.asset)

        imageGenerator.copyCGImage(atExactTime: player.currentTime) { error, cgImage in
            guard let cgImage = cgImage else {
                // TODO: error
                handleErrorWithMessage(error?.localizedDescription, error: error)
                return
            }

            shareImage(UIImage(cgImage: cgImage))
        }
    }

    // MARK: Private

    @IBOutlet private var frameControlsView: VideoFrameControlsView!
    private var playerViewController: AVPlayerViewController!
    private var statusViewController: VideoPlayerStatusControllerTMP!
    private var player: Player?
    private var previewImageRequest: ImageRequest?
}

// MARK: - PlayerDelegate 

extension VideoPlayerViewController: PlayerDelegate {

    func player(_ player: Player, didUpdateStatus status: PlayerStatus) {
        // TODO: BUG, only once!!! (if !=) otherwise flicker
        if case .readyToPlay = status {
            playerViewController.player = player.playerStack?.player
        }

        // Hack: Even though `AVPlayerItem` reports `readyToPlay` its `canStepForward`/`canStepBackward`
        //       properties seem to  be initialized only *after* the KVO observer is executed. Delay update.
        DispatchQueue.main.async {
            self.updateViews()
        }
    }

    func player(_ player: Player, didPeriodicUpateAt time: CMTime) {
        updateCurrentTime()
        // Dimensions can change, update periodically.
        updateDimensions()
    }
}

// MARK: - Private

private extension VideoPlayerViewController {

    func configureViews() {
        view.backgroundColor = .videoPlayerBackground  // TEST (+ maybe not completely black)
        // video background color vs controls view different looks  better -> more structure

        playerViewController.view.backgroundColor = .videoPlayerBackground
        playerViewController.showsPlaybackControls = true
        playerViewController.entersFullScreenWhenPlaybackBegins = false
        playerViewController.exitsFullScreenWhenPlaybackEnds = false

        // TODO: border in frame control (keep + color)
        // TODO: all colors: background not black but almost, controls view color which gray...
    }

    // TODO: errors (+ media reset)
    //  - info on button press
    // TODO: clean up status controller
    // TODO: delayed canstep
    // TODO: error should look good when thumbnail nil (just on background)
    func updateViews() {
        // Might be called before the view is ready (e.g. player status changes, video preview image finishes, ...)
        guard isViewLoaded else { return }

        updateCurrentTime()
        updateDimensions()

        let readyToPlay = player?.status == .readyToPlay
        let canStep = readyToPlay && (player?.canStep ?? false)
        let failed = player?.status == .failed

        statusViewController.previewImage = previewImageRequest?.image
        statusViewController.view.isHidden = readyToPlay
        playerViewController.view.isUserInteractionEnabled = readyToPlay
//        statusViewController.activitiyIndicator.isHidden = readyToPlay

        // todo: Dont show on error!
        if !readyToPlay && !failed {
            statusViewController.activitiyIndicator.start(after: 1.2)  // TODO: only once otherwise delays
        } else {
            statusViewController.activitiyIndicator.stop()
        }

        statusViewController.errorButton.isHidden = !failed

        frameControlsView.previousFrameButtonItem.isEnabled = canStep
        frameControlsView.nextFrameButtonItem.isEnabled = canStep
        frameControlsView.shareButtonItem.isEnabled = readyToPlay
    }

    func updateCurrentTime() {
        frameControlsView.currentTimeLabel.text = VideoCurrentTimeFormatter().string(from: player?.currentTime ?? .zero)
    }

    func updateDimensions() {
        let text = VideoDimensionFormatter().string(from: videoDimension)
        frameControlsView.videoDimensionsLabel.text = text
        frameControlsView.videoDimensionsLabel.isHidden = text == nil
    }

    /// The size of the current player item if available falling back to the actual size of the underlying asset.
    /// Note: The player item size can be less then the asset size, e.g. for lower quality iCloud streams.
    var videoDimension: VideoDimension {
        if let itemSize = player?.currentItem?.presentationSize, itemSize.isValidVideoDimension {
            return itemSize
        }

        return video.asset.pixelSize
    }

    func shareImage(_ image: UIImage) {
        let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityController, animated: true)
    }

    // TODO: (need to keep for avimagegenerator failure)
    func handleErrorWithMessage(_ message: String?, error: Error? = nil, retryAction retry: (() -> ())? = nil) {
        NSLog("Error occured with message: \(String(describing: message ?? nil)), error: \(String(describing: error)).")

        let alert = UIAlertController(title: .defaultAlertTitle,
                                      message: message ?? .defaultAlertMessage,
                                      preferredStyle: UIAlertControllerStyle.alert)

        let ok = UIAlertAction(title: .okAlertAction, style: .default, handler: nil)

        alert.addAction(ok)

        if let retry = retry {
            let retryAction = UIAlertAction(title: .cancelAlertAction, style: .default) { _ in
                retry()
            }
            alert.addAction(retryAction)
        }

        present(alert, animated: true, completion: nil)
    }
}
