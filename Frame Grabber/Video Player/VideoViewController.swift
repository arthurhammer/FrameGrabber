import UIKit
import AVKit

class VideoViewController: UIViewController {

    var video: Video? {
        didSet {
            player.video = video
            updateViews()
        }
    }

    // MARK: - Private IVars

    @IBOutlet private var previousFrameButton: UIButton!
    @IBOutlet private var nextFrameButton: UIButton!
    @IBOutlet private var shareButton: UIButton!
    @IBOutlet private var currentTimeLabel: MonospacedDigitLabel!
    @IBOutlet private var videoDimensionsLabel: MonospacedDigitLabel!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!

    private var videoPlayerViewController: AVPlayerViewController!
    private var player = Player()

    deinit {
        // ??
    }

    // TODO: viewWillAppear: start observing, disappear: stop
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        configurePlayer()
        updateViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillDisappear")
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? AVPlayerViewController {
            videoPlayerViewController = controller
        }
    }

    @IBAction func stepForward() {
        player.step(by: 1)
    }

    @IBAction func stepBackward() {
        player.step(by: -1)
    }

    @IBAction func shareVideoFrame() {
        guard let playerItem = player.currentItem else { return }

        player.pause()

        let imageGenerator = AVAssetImageGenerator(asset: playerItem.asset)

        imageGenerator.copyCGImage(atExactTime: player.currentTime()) { error, cgImage in
            guard let cgImage = cgImage else {
                handleErrorWithMessage(error?.localizedDescription, error: error)
                return
            }

            shareImage(UIImage(cgImage: cgImage))
        }
    }
}

// MARK: - PlayerDelegate 

extension VideoViewController: PlayerDelegate {

    func didUpdateStatus(_ status: VideoStatus, of video: Video) {
        switch status {

        case .loading:
            activityIndicator.startAndShow()

        case .failed(let error):
            handleErrorWithMessage(error?.localizedDescription, error: error) { [weak self] in
                 self?.player.video = self?.player.video
            }

        case .loaded:
            player.play()

        default:
            break
        }

        updateViews()
    }

    func didUpdateStatus(_ status: AVPlayerItemStatus, of playerItem: AVPlayerItem) {
        switch status {

        case .failed:
            handleErrorWithMessage(playerItem.error?.localizedDescription, error: playerItem.error)

            break
        default:
            break
        }

        updateViews()
    }

    func didUpdateStatus(_ status: AVPlayerStatus, of player: Player) {

        switch status {

        case .failed:
            print("Player failed.")
            handleErrorWithMessage(player.error?.localizedDescription, error: player.error)

        default:
            break
        }

        updateViews()
    }

    func didPeriodicUpdate(at time: CMTime) {
        // TODO
        currentTimeLabel.text = VideoTimeFormatter().string(from: player.currentTime())
    }
}

// MARK: - Private

private extension VideoViewController {

    func configureViews() {
        videoPlayerViewController.player = player
        videoPlayerViewController.showsPlaybackControls = true
        videoPlayerViewController.entersFullScreenWhenPlaybackBegins = false
        videoPlayerViewController.exitsFullScreenWhenPlaybackEnds = false
        videoPlayerViewController.view.backgroundColor = .mainBackgroundColor

        previousFrameButton.titleLabel?.adjustsFontSizeToFitWidth = true
        previousFrameButton.titleLabel?.minimumScaleFactor = 0.5
        previousFrameButton.setTitleColor(.white, for: .normal)
        previousFrameButton.tintColor = .accentColor

        nextFrameButton.titleLabel?.adjustsFontSizeToFitWidth = true
        nextFrameButton.titleLabel?.minimumScaleFactor = 0.5
        nextFrameButton.setTitleColor(.white, for: .normal)
        nextFrameButton.tintColor = .accentColor

        let labelSize: CGFloat = 13
        currentTimeLabel.font = UIFont.systemFont(ofSize: labelSize)
        currentTimeLabel.digitFontSize = labelSize
        currentTimeLabel.textColor = .secondaryLabelColor

        videoDimensionsLabel.font = UIFont.systemFont(ofSize: labelSize)
        videoDimensionsLabel.digitFontSize = labelSize
        videoDimensionsLabel.textColor = .secondaryLabelColor

        activityIndicator.isHidden = true
    }

    // TODO
    func updateViews() {
        videoPlayerViewController.view.isUserInteractionEnabled = video != nil

        currentTimeLabel.text = VideoTimeFormatter().string(from: player.currentTime())
        videoDimensionsLabel.text = video != nil ? "\(video!.asset.pixelWidth) 𝖷 \(video!.asset.pixelHeight)" : ""

        let readyToPlay = (video != nil) && (video!.status.isLoaded) && (player.status == .readyToPlay) && (player.currentItem?.status == .readyToPlay)
        let isLoading = (video != nil) && (video!.status.isLoading || video!.status.isLoaded) && (player.status != .failed) && (player.currentItem == nil || player.currentItem?.status == .unknown)
        let canStep = player.canStepBackwardAndForward  // bug here: timing again, item reports false though should report true

        previousFrameButton.isEnabled = readyToPlay //&& canStep
        nextFrameButton.isEnabled = readyToPlay // && canStep
        shareButton.isEnabled = readyToPlay

            activityIndicator.isHidden = !isLoading

        // todo
//        if video == nil {
//            previousFrameButton.isHidden = true
//            nextFrameButton.isHidden = true
//            currentTimeLabel.isHidden = true
//            videoDimensionsLabel.isHidden = true
//            shareButton.isHidden = true
//        }
    }

    func configurePlayer() {
        player.delegate = self
        player.isMuted = true  // Initially muted
    }

    func shareImage(_ image: UIImage) {
        let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityController, animated: true)
    }

    // Temp
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
