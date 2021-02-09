import ThumbnailSlider
import UIKit

/// Shows, hides, updates the current scrubbing speed.
class ScrubbingIndicatorView: UIVisualEffectView {

    @IBOutlet private(set) var speedLabel: UILabel!
    @IBOutlet private(set) var icon: UIImageView!

    private var previousSpeed: Float?
    private var shouldShow = false {
        didSet { show(shouldShow) }
    }
    private lazy var formatter = NumberFormatter.percentFormatter()

    private let hintDelay: TimeInterval = 1
    private let animationDuration: TimeInterval = 0.25

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        layer.cornerCurve = .continuous
    }

    func configure(for slider: ScrubbingThumbnailSlider) {
        slider.addTarget(self, action: #selector(startScrubbing), for: .touchDown)
        slider.addTarget(self, action: #selector(scrub), for: .valueChanged)
        slider.addTarget(self, action: #selector(endScrubbing), for: [.touchUpInside, .touchUpOutside])
    }

    @objc private func startScrubbing(_ sender: ScrubbingThumbnailSlider) {
        shouldShow = false
        previousSpeed = sender.currentScrubbingSpeed.speed

        // Either show after `hintDelay` automatically or when the user first uses speed. Whichever comes first.
        perform(#selector(hint), with: nil, afterDelay: hintDelay)
    }

    @objc private func scrub(_ sender: ScrubbingThumbnailSlider) {
        let speed = sender.currentScrubbingSpeed.speed
        shouldShow = shouldShow || (speed != previousSpeed)
        previousSpeed = speed

        speedLabel.text = formatter.string(from: speed as NSNumber)
        icon.image = image(forSpeed: speed)
    }

    @objc private func endScrubbing(_ sender: ScrubbingThumbnailSlider) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hint), object: nil)
        shouldShow = false
    }

    private func configureViews() {
        clipsToBounds = true
        alpha = 0
        speedLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        icon.preferredSymbolConfiguration = .init(pointSize: 12, weight: .semibold, scale: .small)
    }

    @objc private func hint() {
        shouldShow = true
    }

    private func show(_ show: Bool) {
        UIView.animate(withDuration: animationDuration, delay: 0, options: .beginFromCurrentState, animations: {
            self.alpha = show ? 1 : 0
        })
    }

    private func image(forSpeed speed: Float) -> UIImage? {
        (speed == 1) ? UIImage(systemName: "hare.fill") : UIImage(systemName: "tortoise.fill")
    }
}
