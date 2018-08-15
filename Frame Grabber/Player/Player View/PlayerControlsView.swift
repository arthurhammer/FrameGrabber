import UIKit

class PlayerControlsView: GradientView {

    @IBOutlet var timeSlider: TimeSlider!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var shareButton: UIButton!
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
        playButton.isEnabled = enabled
        nextButton.isEnabled = enabled
        previousButton.isEnabled = enabled
        shareButton.isEnabled = enabled
    }

    private func configureViews() {
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .bold)

        timeSlider.valueIndicatorColor = .timeSliderValueIndicator
        timeSlider.trackColor = .timeSliderTrack
        timeSlider.disabledTrackColor = .disabledTimeSliderTrack

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
