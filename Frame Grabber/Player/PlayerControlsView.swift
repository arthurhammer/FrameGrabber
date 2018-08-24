import UIKit

class PlayerControlsView: GradientView {

    @IBOutlet var timeSlider: TimeSlider!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var shareButton: UIButton!
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var previousButton: RepeatingButton!
    @IBOutlet var nextButton: RepeatingButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    func setControlsEnabled(_ enabled: Bool) {
        timeSlider.isEnabled = enabled
        timeLabel.isEnabled = enabled
        shareButton.isEnabled = enabled
        playButton.isEnabled = enabled
        nextButton.isEnabled = enabled
        previousButton.isEnabled = enabled
    }

    private func configureViews() {
        colors = Style.Color.overlayBottomGradient

        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)

        timeSlider.trackCornerRadius = timeSlider.trackHeight / 2
        timeSlider.trackEdgeCornerRadius = 4
        timeSlider.trackColor = Style.Color.timeSlider
        timeSlider.disabledTrackColor = Style.Color.disabledTimeSlider

        previousButton.tintColor = Style.Color.timeSlider
        nextButton.tintColor = Style.Color.timeSlider
        shareButton.backgroundColor = .mainTint
        shareButton.layer.cornerRadius = shareButton.bounds.height/2

        applyOverlayShadow()
    }
}


// MARK: - Play Button

import AVKit

extension UIButton {
    func setTimeControlStatus(_ status: AVPlayerTimeControlStatus) {
        setImage((status == .paused) ? #imageLiteral(resourceName: "play") : #imageLiteral(resourceName: "pause"), for: .normal)
    }
}
