import ThumbnailSlider
import UIKit

class EditorToolbar: UIView {

    @IBOutlet var timeSlider: ScrubbingThumbnailSlider!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var timeSpinner: UIActivityIndicatorView!
    @IBOutlet var speedButton: UIButton!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var previousButton: RepeatingButton!
    @IBOutlet var nextButton: RepeatingButton!
    @IBOutlet var shareButton: UIButton!
    
    private let spinnerScale: CGFloat = 0.75

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    func setEnabled(_ enabled: Bool) {
        timeSlider.isEnabled = enabled
        timeLabel.isEnabled = enabled
        speedButton.isEnabled = enabled
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
        
        timeSpinner.transform = CGAffineTransform.identity
            .scaledBy(x: spinnerScale, y: spinnerScale)
        
        configureTimeLabel()
        configureSpeedButton()
    }
    
    private func configureTimeLabel() {
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        timeLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                
        let handleConstraint = timeLabel.superview?.centerXAnchor.constraint(
            equalTo: timeSlider.handleLayoutGuide.centerXAnchor
        )
        
        handleConstraint?.priority = .defaultHigh
        handleConstraint?.isActive = true
    }
    
    private func configureSpeedButton() {
        speedButton.superview?.bringSubviewToFront(speedButton)
        
        speedButton.leadingAnchor.constraint(
            greaterThanOrEqualTo: timeSlider.handleLayoutGuide.trailingAnchor,
            constant: 8
        ).isActive = true
        
        speedButton.layer.cornerCurve = .continuous
        speedButton.layer.cornerRadius = 12
        speedButton.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
    }
}

// MARK: - Play Button

import AVFoundation

extension UIButton {
    func setTimeControlStatus(_ status: AVPlayer.TimeControlStatus) {
        setImage((status == .paused) ? UIImage(systemName: "play.fill") : UIImage(systemName: "pause.fill"), for: .normal)
    }
}
