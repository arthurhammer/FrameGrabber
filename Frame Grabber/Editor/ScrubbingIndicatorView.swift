import ThumbnailSlider
import UIKit

/// Shows, hides, updates the current scrubbing speed.
class ScrubbingIndicatorView: UIVisualEffectView {

    @IBOutlet private(set) var speedLabel: UILabel!

    private var previousSpeed: Float?
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

    func configure(for slider: ScrubbingThumbnailSlider) {
        slider.addTarget(self, action: #selector(startScrubbing), for: .touchDown)
        slider.addTarget(self, action: #selector(scrub), for: .valueChanged)
        slider.addTarget(self, action: #selector(endScrubbing), for: [.touchUpInside, .touchUpOutside])
    }

    @objc private func startScrubbing(_ sender: ScrubbingThumbnailSlider) {
        isUsingSpeed = false
        previousSpeed = sender.currentScrubbingSpeed.speed
    }

    @objc private func scrub(_ sender: ScrubbingThumbnailSlider) {
        let speed = sender.currentScrubbingSpeed.speed
        isUsingSpeed = isUsingSpeed || (speed != previousSpeed)
        speedLabel.text = formatter.string(from: speed as NSNumber)
        show(isUsingSpeed)
        previousSpeed = speed
    }

    @objc private func endScrubbing(_ sender: ScrubbingThumbnailSlider) {
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
