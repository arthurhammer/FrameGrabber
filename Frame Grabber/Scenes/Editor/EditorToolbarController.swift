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
        if preferredContentSize != view.bounds.size {
            preferredContentSize = view.bounds.size
        }
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
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
