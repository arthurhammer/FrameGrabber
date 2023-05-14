import AVFoundation
import Combine
import ThumbnailSlider
import UIKit

protocol EditorToolbarControllerDelegate: AnyObject {
    func controller(_ controller: EditorToolbarController, didSelectShareFrameAt time: CMTime)
}

class EditorToolbarController: UIViewController {
    
    weak var delegate: EditorToolbarControllerDelegate?
        
    let playbackController: PlaybackController

    var placeholderImage: UIImage? {
        didSet { updateViews() }
    }
    
    var timeFormat: TimeFormat = .minutesSecondsMilliseconds {
        didSet { updateViews()  }
    }
    
    var exportAction: ExportAction = .showShareSheet {
        didSet { updateViews() }
    }
    
    var isScrubbing: Bool {
        toolbar.timeSlider.isTracking
    }
    
    @IBOutlet private(set) var toolbar: EditorToolbar!
    
    private lazy var timeFormatter = VideoTimeFormatter()
    private var sliderDataSource: AVAssetThumbnailSliderDataSource?
    private lazy var feedbackGenerator = UISelectionFeedbackGenerator()
    private lazy var bindings = Set<AnyCancellable>()
    
    init?(
        playbackController: PlaybackController,
        delegate: EditorToolbarControllerDelegate? = nil,
        coder: NSCoder
    ) {
        self.playbackController = playbackController
        self.delegate = delegate
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        configureViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()        
        updateExpandedPreferredContentSize()
    }
    
    // MARK: - Actions
    
    @IBAction func playOrPause() {
        guard !isScrubbing else { return }
        playFeedback()
        playbackController.playOrPause()
    }

    @IBAction func stepBackward() {
        guard !isScrubbing else { return }
        playFeedback()
        playbackController.step(byCount: -1)
    }

    @IBAction func stepForward() {
        guard !isScrubbing else { return }
        playFeedback()
        playbackController.step(byCount: 1)
    }

    @IBAction func shareFrames() {
        guard !isScrubbing else { return }

        playFeedback()
        playbackController.pause()
        
        let time = playbackController.currentSampleTime ?? playbackController.currentPlaybackTime
        delegate?.controller(self, didSelectShareFrameAt: time)
    }

    @IBAction func scrub(_ sender: ScrubbingThumbnailSlider) {
        playbackController.smoothlySeek(to: sender.time)
    }
    
    private func playFeedback() {
        feedbackGenerator.selectionChanged()
        feedbackGenerator.prepare()
    }
    
    // MARK: - Configuring
    
    private func configureViews() {
        sliderDataSource = AVAssetThumbnailSliderDataSource(
            slider: toolbar.timeSlider,
            asset: nil,  // Set in binding, avoid triggering work twice.
            placeholderImage: placeholderImage
        )
        
        toolbar.backgroundColor = .editorBars
        toolbar.configureWithBarShadow()
        toolbar.timeSlider.scrubbingSpeeds = [EditorSpeedMenu.defaultSpeed.scrubbingSpeed]
        toolbar.speedButton.showsMenuAsPrimaryAction = true
        updateSpeedButton()
        
        configureBindings()
        updateViews()
    }
    
    func updateViews() {
        guard isViewLoaded else { return }
        
        sliderDataSource?.placeholderImage = placeholderImage
        toolbar.shareButton.setImage(exportAction.icon, for: .normal)
        
        let time = playbackController.currentSampleTime ?? playbackController.currentPlaybackTime
        updateTimeLabel(withTime: time)
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
    
    func updateSpeedButton() {
        let current = EditorSpeedMenu.Selection(toolbar.timeSlider.currentScrubbingSpeed)
        toolbar.speedButton.setImage(current.buttonIcon, for: .normal)
                    
        toolbar.speedButton.menu = EditorSpeedMenu.menu(with: current) {
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
        
        switch timeFormat {
        
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
                toolbar.timeLabel.text = timeFormatter.string(from: time) + "."
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
