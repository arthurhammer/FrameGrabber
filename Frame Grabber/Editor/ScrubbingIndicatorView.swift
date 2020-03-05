import UIKit

/// Shows, hides, updates the current scrubbing speed in response to the `TimeSlider`
/// instance configured in the storyboard.
class ScrubbingIndicatorView: UIVisualEffectView {

    @IBOutlet var speedLabel: UILabel!

    private var previousSpeed: Float?
    private var previousPreviousSpeed: Float?
    private var isUsingSpeed = false
    private lazy var formatter = NumberFormatter.percentFormatter()

    private let animationDuration: TimeInterval = 0.25

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    @IBAction private func startScrubbing(_ sender: TimeSlider) {
        isUsingSpeed = false
        (previousPreviousSpeed, previousSpeed) = (sender.currentScrubbingSpeed.speed, sender.currentScrubbingSpeed.speed)
    }

    @IBAction private func scrub(_ sender: TimeSlider) {
        let speed = sender.currentScrubbingSpeed.speed
        isUsingSpeed = isUsingSpeed || (speed != previousSpeed)
        speedLabel.text = formatter.string(from: speed as NSNumber)
        show(isUsingSpeed)
        (previousPreviousSpeed, previousSpeed) = (previousSpeed, speed)
    }

    @IBAction private func endScrubbing(_ sender: TimeSlider) {
        // The slider resets its speed to 1 when ending. For the fade out, preserve the
        // effective speed the scrubbing ended with.
        speedLabel.text = previousPreviousSpeed.flatMap { formatter.string(from: $0 as NSNumber) }
        show(false)
    }

    private func configureViews() {
        clipsToBounds = true
        alpha = 0
        speedLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
    }

    private func show(_ show: Bool) {
        UIView.animate(withDuration: animationDuration, delay: 0, options: .beginFromCurrentState, animations: {
            self.alpha = show ? 1 : 0
        }, completion: nil)
    }
}
