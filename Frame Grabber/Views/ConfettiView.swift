// Includes portions from SAConfettiView by Sudeep Agarwal:
//   Copyright (c) 2015 Sudeep Agarwal, MIT License
//   https://github.com/sudeepag/SAConfettiView
//
// Some ideas taken from Bryce Pauken:
//   https://bryce.co/recreating-imessage-confetti/

import Foundation
import UIKit

// TODO: Attributions

public class ConfettiView: UIView {

    public var colors = [
        (r:149, g:58, b:255), (r:255, g:195, b:41), (r: 255,g: 101,b: 26),
        (r:123, g:92, b:255), (r:76, g:126, b:255), (r: 71,g: 192,b: 255),
        (r:255, g:47, b:39), (r:255, g:91, b:134), (r: 233,g: 122,b: 208)
    ]
    .map { UIColor(red: ($0.r / 255.0), green: ($0.g / 255.0), blue: ($0.b / 255.0), alpha: 1) }

    public var amount = 40
    public var intensity: Float = 0.75

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
    
    private lazy var cells: [CAEmitterCell] = {
        (0...amount)
            .map { _ in
                Confetti(color: colors.randomElement()!, shape: .allCases.randomElement()!)
            }.map {
                cell(for: $0)
            }
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
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.minY - 100)
        emitter.emitterSize = CGSize(width: bounds.width, height: 1)
    }

    /// Starts animating confetti.
    ///
    /// If `duration` is nil, animates indefinitely. Otherwise, animates for the specified
    /// amount of time (unless `stopConfetti` is called prior to that).
    public func startConfetti(withDuration duration: TimeInterval? = nil) {
        stopConfetti()

        if let duration = duration, duration > 0 {
            timer = .scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?.stopConfetti()
            }
        }

        emitter.birthRate = 1
        emitter.emitterCells = cells
    }
    
    public func stopConfetti() {
        cancelTimer()
        emitter.birthRate = 0
    }

    private func configureViews() {
        isUserInteractionEnabled = false
        clipsToBounds = true
    }

    private func cell(for confetti: Confetti) -> CAEmitterCell {
        var confetti = confetti
        
        let cell = CAEmitterCell()
        cell.name = UUID().uuidString
        cell.contents = confetti.image?.cgImage
        cell.color = confetti.color.cgColor

        cell.birthRate = 6 * intensity
        cell.lifetime = 20 * intensity
        cell.lifetimeRange = 0
        cell.velocity = CGFloat(350 * intensity)
        cell.velocityRange = CGFloat(80 * intensity)
        cell.emissionLongitude = CGFloat(Double.pi)
        cell.emissionRange = CGFloat(Double.pi)
        cell.spin = CGFloat(3.5 * intensity)
        cell.spinRange = CGFloat(4 * intensity)
        cell.scaleRange = CGFloat(intensity)
        cell.scaleSpeed = CGFloat(-0.1 * intensity)

        return cell
    }

    private func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Confetti

private struct Confetti {
    enum Shape: CaseIterable {
        case rectangle
        case circle
    }
    
    let color: UIColor
    let shape: Shape
    
    private(set) lazy var image: UIImage? = {
        let imageRect: CGRect = {
            switch shape {
            case .rectangle:
                return CGRect(x: 0, y: 0, width: 20, height: 13)
            case .circle:
                return CGRect(x: 0, y: 0, width: 10, height: 10)
            }
        }()

        UIGraphicsBeginImageContext(imageRect.size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)

        switch shape {
        case .rectangle:
            context.fill(imageRect)
        case .circle:
            context.fillEllipse(in: imageRect)
        }

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }()
}
