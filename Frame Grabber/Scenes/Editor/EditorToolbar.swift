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
        if #available(iOS 14, *) {
            configureSpeedButton()
        } else {
            speedButton.isHidden = true
        }
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
    
    @available(iOS 14, *)
    private func configureSpeedButton() {
        speedButton.leadingAnchor.constraint(
            greaterThanOrEqualTo: timeSlider.handleLayoutGuide.trailingAnchor,
            constant: 8
        ).isActive = true
        
        speedButton.tintColor = .label
        timeSlider.bringSubviewToFront(speedButton)
        
        configureSpeedButtonBlurView()
    }
    
    @available(iOS 14, *)
    private func configureSpeedButtonBlurView() {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
        blurView.layer.cornerRadius = timeSlider.layer.cornerRadius - timeSlider.layer.borderWidth
        blurView.layer.cornerCurve = .continuous
        blurView.clipsToBounds = true

        timeSlider.insertSubview(blurView, belowSubview: speedButton)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        
        blurView.leadingAnchor.constraint(equalTo: speedButton.leadingAnchor).isActive = true
        blurView.trailingAnchor.constraint(equalTo: speedButton.trailingAnchor).isActive = true
        blurView.topAnchor.constraint(equalTo: speedButton.topAnchor).isActive = true
        blurView.bottomAnchor.constraint(equalTo: speedButton.bottomAnchor).isActive = true
    }
}

// MARK: - Play Button

import AVFoundation

extension UIButton {
    func setTimeControlStatus(_ status: AVPlayer.TimeControlStatus) {
        setImage((status == .paused) ? UIImage(systemName: "play.fill") : UIImage(systemName: "pause.fill"), for: .normal)
    }
}
