import ThumbnailSlider
import UIKit

class EditorToolbar: UIView {

    @IBOutlet var timeSlider: ScrubbingThumbnailSlider!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var timeSpinner: UIActivityIndicatorView!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var previousButton: RepeatingButton!
    @IBOutlet var nextButton: RepeatingButton!
    @IBOutlet var shareButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    func setEnabled(_ enabled: Bool) {
        timeSlider.isEnabled = enabled
        timeLabel.isEnabled = enabled
        shareButton.isEnabled = enabled
        playButton.isEnabled = enabled
        nextButton.isEnabled = enabled
        previousButton.isEnabled = enabled
    }

    private func configureViews() {
        backgroundColor = nil

        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(blurView, at: 0)
        
        configureTimeLabel()
        
        timeSpinner.transform = CGAffineTransform.identity.scaledBy(x: 0.75, y: 0.75)
    }
    
    private func configureTimeLabel() {
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        
        timeLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        let timeContainer = timeLabel.superview
        
        let handleConstraint = timeContainer?.centerXAnchor.constraint(
            equalTo: timeSlider.handleLayoutGuide.centerXAnchor
        )
        handleConstraint?.priority = .defaultHigh
        handleConstraint?.isActive = true
    }
}

// MARK: - Play Button

import AVFoundation

extension UIButton {
    func setTimeControlStatus(_ status: AVPlayer.TimeControlStatus) {
        setImage((status == .paused) ? UIImage(systemName: "play.fill") : UIImage(systemName: "pause.fill"), for: .normal)
    }
}
