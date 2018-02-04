import UIKit

class PlayerControlsView: GradientView {

    @IBOutlet var timeSlider: PlayerSlider!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var shareButton: UIButton!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var previousButton: RepeatingButton!
    @IBOutlet var nextButton: RepeatingButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

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

        shareButton.layer.cornerRadius = shareButton.bounds.height/2
        shareButton.backgroundColor = .accent
    }
}
