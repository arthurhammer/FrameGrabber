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

    func setPlayerControlsEnabled(_ enabled: Bool) {
        timeSlider.isEnabled = enabled
        timeLabel.isEnabled = enabled
        shareButton.isEnabled = enabled
        playButton.isEnabled = enabled
        nextButton.isEnabled = enabled
        previousButton.isEnabled = enabled
    }

    private func configureViews() {
        colors = UIColor.playerOverlayControlsGradient
        applyDefaultOverlayShadow()

        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)

        timeSlider.valueIndicatorColor = .timeSliderValueIndicator
        timeSlider.trackColor = .timeSliderTrack
        timeSlider.disabledTrackColor = .disabledTimeSliderTrack

        previousButton.tintColor = .timeSliderTrack
        nextButton.tintColor = .timeSliderTrack

        shareButton.layer.cornerRadius = shareButton.bounds.height/2
        shareButton.backgroundColor = .accent
    }
}


// MARK: - Play Button

import AVKit

extension UIButton {
    func setTimeControlStatus(_ status: AVPlayerTimeControlStatus) {
        setImage((status == .paused) ? #imageLiteral(resourceName: "play") : #imageLiteral(resourceName: "pause"), for: .normal)
    }
}
