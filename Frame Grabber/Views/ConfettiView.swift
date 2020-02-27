// Includes portions from SAConfettiView by Sudeep Agarwal:
//   Copyright (c) 2015 Sudeep Agarwal, MIT License
//   https://github.com/sudeepag/SAConfettiView

import UIKit

public class ConfettiView: UIView {

    public var confettiImage: UIImage?

    public var intensity: Float = 0.75

    public var colors = [UIColor(red: 0.95, green: 0.40, blue: 0.27, alpha: 1.0),
                         UIColor(red: 1.00, green: 0.78, blue: 0.36, alpha: 1.0),
                         UIColor(red: 0.48, green: 0.78, blue: 0.64, alpha: 1.0),
                         UIColor(red: 0.30, green: 0.76, blue: 0.85, alpha: 1.0),
                         UIColor(red: 0.58, green: 0.39, blue: 0.55, alpha: 1.0)]

    var isActive: Bool {
        emitter.birthRate > 0
    }

    private lazy var emitter: CAEmitterLayer = {
        let emitter = CAEmitterLayer()
        emitter.birthRate = 0
        emitter.emitterShape = .line
        layer.addSublayer(emitter)
        return emitter
    }()

    private var timer: Timer?

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureViews()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    deinit {
        cancelTimer()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        emitter.frame = bounds
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: 0)
        emitter.emitterSize = CGSize(width: bounds.width, height: 1)
    }

    /// Starts animating confetti.
    ///
    /// If `duration` is nil, animates indefinitely. Otherwise, animates for the specified
    /// amount of time (unless `stopConfetti` is called prior to that).
    public func startConfetti(withDuration duration: TimeInterval? = nil) {
        cancelTimer()

        if let duration = duration, duration > 0 {
            timer = .scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?.stopConfetti()
            }
        }

        emitter.birthRate = 1
        emitter.emitterCells = colors.map(confetti)
    }

    public func stopConfetti() {
        cancelTimer()
        emitter.birthRate = 0
    }

    private func configureViews() {
        isUserInteractionEnabled = false
        clipsToBounds = true
    }

    private func confetti(withColor color: UIColor) -> CAEmitterCell {
        let confetti = CAEmitterCell()

        confetti.contents = confettiImage?.cgImage
        confetti.color = color.cgColor

        confetti.birthRate = 6 * intensity
        confetti.lifetime = 20 * intensity
        confetti.lifetimeRange = 0
        confetti.velocity = CGFloat(350 * intensity)
        confetti.velocityRange = CGFloat(80 * intensity)
        confetti.emissionLongitude = CGFloat(Double.pi)
        confetti.emissionRange = CGFloat(Double.pi)
        confetti.spin = CGFloat(3.5 * intensity)
        confetti.spinRange = CGFloat(4 * intensity)
        confetti.scaleRange = CGFloat(intensity)
        confetti.scaleSpeed = CGFloat(-0.1 * intensity)

        return confetti
    }

    private func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }
}
