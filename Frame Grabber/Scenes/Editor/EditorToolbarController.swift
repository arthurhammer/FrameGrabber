import AVFoundation
import Combine
import ThumbnailSlider
import UIKit

protocol EditorToolbarControllerDelegate: class {
    func controller(_ controller: EditorToolbarController, didSelectShareFrameAt time: CMTime)
}

class EditorToolbarController: UIViewController {
    
    weak var delegate: EditorToolbarControllerDelegate?
        
    let playbackController: PlaybackController
    let settings: UserDefaults = .standard
    
    var isScrubbing: Bool {
        toolbar.timeSlider.isTracking
    }
    
    @IBOutlet var toolbar: EditorToolbar!
    
    private lazy var timeFormatter = VideoTimeFormatter()
    private var sliderDataSource: AVAssetThumbnailSliderDataSource?
    private lazy var selectionFeedbackGenerator = UISelectionFeedbackGenerator()
    private lazy var bindings = Set<AnyCancellable>()
    
    init?(playbackController: PlaybackController, coder: NSCoder) {
        self.playbackController = playbackController
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()        
        updateExpandedPreferredContentSize()
    }
    
    // MARK: - Actions
    
    @IBAction func playOrPause() {
        guard !isScrubbing else { return }
        playSelectionFeedback()
        playbackController.playOrPause()
    }

    @IBAction func stepBackward() {
        guard !isScrubbing else { return }
        playSelectionFeedback()
        playbackController.step(byCount: -1)
    }

    @IBAction func stepForward() {
        guard !isScrubbing else { return }
        playSelectionFeedback()
        playbackController.step(byCount: 1)
    }

    @IBAction func shareFrames() {
        guard !isScrubbing else { return }

        playSelectionFeedback()
        playbackController.pause()
        
        let time = playbackController.currentSampleTime ?? playbackController.currentPlaybackTime
        delegate?.controller(self, didSelectShareFrameAt: time)
    }

    @IBAction func scrub(_ sender: ScrubbingThumbnailSlider) {
        playbackController.smoothlySeek(to: sender.time)
    }
    
    private func playSelectionFeedback() {
        selectionFeedbackGenerator.selectionChanged()
        selectionFeedbackGenerator.prepare()
    }
    
    // MARK: - Configuring
    
    private func configureViews() {
        // TODO: place holder image
        sliderDataSource = AVAssetThumbnailSliderDataSource(
            slider: toolbar.timeSlider,
            asset: nil,
            placeholderImage: nil // videoController.previewImage
        )
        
        toolbar.shareButton.setImage(settings.exportAction.icon, for: .normal)
        
        if #available(iOS 14.0, *) {
            toolbar.timeSlider.scrubbingSpeeds = [EditorSpeedMenu.defaultScrubbingSpeed]
            toolbar.speedButton.showsMenuAsPrimaryAction = true
            updateSpeedButton()
        } else {
            // Use the old vertical sliding speed configuration.
            toolbar.speedButton.isHidden = true
        }
        
        configureBindings()
    }
    
    func configureBindings() {
        playbackController
            .$asset
            .assignWeak(to: \.asset, on: sliderDataSource)
            .store(in: &bindings)
        
        playbackController
            .$status
            .map { $0 == .readyToPlay }
            .sink { [weak self] in
                self?.toolbar.setEnabled($0)
                self?.navigationItem.rightBarButtonItem?.isEnabled = $0
            }
            .store(in: &bindings)

        playbackController
            .$duration
            .assignWeak(to: \.duration, on: toolbar.timeSlider)
            .store(in: &bindings)

        playbackController
            .$currentPlaybackTime
            .sink { [weak self] time in
                guard self?.isScrubbing == false else { return }
                self?.toolbar.timeSlider.setTime(time, animated: false)
            }
            .store(in: &bindings)
        
        playbackController
            .$currentSampleTime
            .sink { [weak self] time in
                let time = time ?? self?.playbackController.currentPlaybackTime ?? .zero
                self?.updateTimeLabel(withTime: time)
            }
            .store(in: &bindings)

        playbackController
            .$timeControlStatus
            .sink { [weak self] in
                self?.toolbar.playButton.setTimeControlStatus($0)
            }
            .store(in: &bindings)
    }
    
    @available(iOS 14, *)
    func updateSpeedButton() {
        let current = toolbar.timeSlider.currentScrubbingSpeed
                    
        toolbar.speedButton.menu = EditorSpeedMenu.menu(withCurrentSpeed: current) {
            [weak self] selection in
            self?.toolbar.timeSlider.scrubbingSpeeds = [selection.scrubbingSpeed]
            self?.updateSpeedButton()
        }
    }
    
    // TODO: Clean this up.
    func updateTimeLabel(withTime time: CMTime) {
        // Loading or playing.
        guard !playbackController.isPlaying && (playbackController.status == .readyToPlay) else {
            toolbar.timeSpinner.isHidden = true
            toolbar.timeLabel.text = timeFormatter.string(from: time)
            return
        }
        
        switch settings.timeFormat {
        
        case .minutesSecondsMilliseconds:
            toolbar.timeLabel.text = timeFormatter.string(from: time, includeMilliseconds: true)
        
        case .minutesSecondsFrameNumber:
            // Succeeded indexing.
            if let frameNumber = playbackController.relativeFrameNumber(for: time) {
                toolbar.timeSpinner.isHidden = true
                toolbar.timeLabel.text = timeFormatter.string(from: time, frameNumber: frameNumber)
            // Still indexing.
            } else if playbackController._isIndexingSampleTimes {
                toolbar.timeSpinner.isHidden = false
                toolbar.timeLabel.text = timeFormatter.string(from: time) + " /"
            // Failed indexing.
            } else {
                toolbar.timeSpinner.isHidden = true
                toolbar.timeLabel.text = timeFormatter.string(from: time)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
