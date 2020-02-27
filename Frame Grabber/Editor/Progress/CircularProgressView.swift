import UIKit

class CircularProgressView: UIView {

    var progress: Float {
        get { progressLayer.progress }
        set { setProgress(newValue, animated: false) }
    }

    func setProgress(_ progress: Float, animated: Bool) {
        let progress = min(max(0, progress), 1)
        progressLayer.animatesProgress = animated
        progressLayer.progress = progress
    }

    /// The color for the portion of the progress view that is filled.
    var progressTintColor: UIColor = .label {
        didSet { updateColors() }
    }

    /// The color for the portion of the progress view that is not filled.
    var trackTintColor: UIColor = .clear {
        didSet { updateColors() }
    }

    override static var layerClass: AnyClass {
        ProgressLayer.self
    }

    private var progressLayer: ProgressLayer {
        layer as! ProgressLayer
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureViews()
    }

    private func configureViews() {
        isOpaque = false
        progressLayer.contentsScale = UIScreen.main.scale
        updateColors()
        setProgress(0, animated: false)
    }

    private func updateColors() {
        traitCollection.performAsCurrent {
            progressLayer.progressTintColor = progressTintColor.cgColor
            progressLayer.trackTintColor = trackTintColor.cgColor
        }
    }
}

private class ProgressLayer: CALayer {

    // Synthesizes KVC-compliant accessors.
    @NSManaged var progress: Float
    @NSManaged var progressTintColor: CGColor
    @NSManaged var trackTintColor: CGColor

    var animatesProgress: Bool = false

    private let animationDuration: TimeInterval = 0.2
    private let lineWidth: CGFloat = 2

    override class func needsDisplay(forKey key: String) -> Bool{
        key == #keyPath(progress)
            || key == #keyPath(progressTintColor)
            || key == #keyPath(trackTintColor)
            || super.needsDisplay(forKey: key)
    }

    // Implicit layer animations.
    //   See: https://www.objc.io/issues/12-animations/animating-custom-layer-properties/
    override func action(forKey key: String) -> CAAction? {
        guard animatesProgress, key == #keyPath(progress) else {
            return super.action(forKey: key)
        }

        let animation = CABasicAnimation(keyPath: key)
        animation.duration = animationDuration
        animation.fromValue = presentation()?.value(forKey: key)
        return animation
    }

    override func draw(in ctx: CGContext) {
        let circleRect = bounds.insetBy(dx: 1, dy: 1)

        ctx.setFillColor(trackTintColor)
        ctx.setStrokeColor(progressTintColor)
        ctx.setLineWidth(lineWidth)

        ctx.fillEllipse(in: circleRect)
        ctx.strokeEllipse(in: circleRect)

        let radius = min(circleRect.midX, circleRect.midY)
        let center = CGPoint(x: radius, y: circleRect.midY)
        let startAngle = -.pi / 2.0
        let endAngle = startAngle + 2 * .pi * Double(progress)

        ctx.setFillColor(progressTintColor)
        ctx.move(to: center)
        ctx.addArc(center: center, radius: radius, startAngle: CGFloat(startAngle), endAngle: CGFloat(endAngle), clockwise: false)
        ctx.closePath()
        ctx.fillPath()
    }
}
