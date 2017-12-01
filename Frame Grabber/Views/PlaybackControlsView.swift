import UIKit

// TODO effectview; constraints, simplify stack views, verify buttons correct size, ACTIVITY INDICATOR
// BUG: when labels hidden -> constraints shrink -> ugly keep fixed

class PlaybackControlsView: UIView {

    @IBOutlet var timeSlider: ScrubbingSlider!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var dimensionsLabel: UILabel!
    @IBOutlet var labelsContainer: UIView!

    @IBOutlet var playButton: UIButton!
    @IBOutlet var previousButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var shareButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    // TODO
    func setPlayerControlsEnabled(_ enabled: Bool) {
        playButton.isEnabled = enabled
        nextButton.isEnabled = enabled
        previousButton.isEnabled = enabled
        shareButton.isEnabled = enabled
        timeSlider.isEnabled = enabled
    }

    // TODO
    func setActivityIndicatorEnabled(_ enabled: Bool) {
        if enabled {
            labelsContainer.isHidden = true
            activityIndicator.start(animated: true)
        } else {
            activityIndicator.stop()
            labelsContainer.isHidden = false
        }
    }

    private func configureViews() {
        backgroundColor = nil

        layer.cornerRadius = 16
        layer.masksToBounds = true

        // Scrubber
        let thumbSize = CGSize(width: 2, height: 30)
        let trackHeight: CGFloat = 6
        timeSlider.setThumbSize(thumbSize, cornerRadius: thumbSize.width/2, color: .accent, for: .normal)
        timeSlider.setMinimumTrackHeight(trackHeight, cornerRadius: trackHeight/2, color: .timeScrubberMinimumTrack, for: .normal)
        timeSlider.setMaximumTrackHeight(trackHeight, cornerRadius: trackHeight/2, color: .timeScrubberMaximumTrack, for: .normal)

        // Labels
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        timeLabel.textColor = .playbackControlsTint

        dimensionsLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        dimensionsLabel.textColor = .playbackControlsTint

        // Buttons
        tintColor = .playbackControlsTint
        shareButton.tintColor = .accent

        // Initial states
        timeSlider.value = 0
        timeLabel.text = " "  // Fixed size. Nil or empty would make it jump around when re-appearing.
        dimensionsLabel.text = " "
        activityIndicator.stop()
        setPlayerControlsEnabled(false)
    }
}
