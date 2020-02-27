import UIKit

/// The fraction of the default speed and the vertical distance at which it takes effect.
struct ScrubbingSpeed {
    let speed: Float
    let verticalDistance: CGFloat
}

extension ScrubbingSpeed: Comparable {

    static let defaultSpeeds: [ScrubbingSpeed] = [
        ScrubbingSpeed(speed: 1, verticalDistance: 0),
        ScrubbingSpeed(speed: 0.5, verticalDistance: 70),
        ScrubbingSpeed(speed: 0.25, verticalDistance: 120),
        ScrubbingSpeed(speed: 0.1, verticalDistance: 170)
    ]

    static func <(lhs: ScrubbingSpeed, rhs: ScrubbingSpeed) -> Bool {
        (lhs.verticalDistance == rhs.verticalDistance)
            ? lhs.speed < rhs.speed
            : lhs.verticalDistance < rhs.verticalDistance
    }
}

/// A slider with variable scrubbing speeds.
class ScrubbingSlider: UISlider {

    /// The current scrubbing speed.
    private(set) lazy var scrubbingSpeed = scrubbingSpeeds.first!.speed

    /// The scrubbing speed configuration. Cannot be empty.
    var scrubbingSpeeds = ScrubbingSpeed.defaultSpeeds {
        didSet {
            guard !scrubbingSpeeds.isEmpty else { fatalError("Scrubbing speeds cannot be empty.") }
            scrubbingSpeeds.sort()
        }
    }

    private var initialTrackingLocation: CGPoint = .zero
    /// `value` if it weren't adjusted for speed (i.e. where the finger actually is).
    private lazy var unadjustedValue = value
    private lazy var previousValue = value
    private lazy var previousSpeed = scrubbingSpeed
    private var feedbackGenerator: UISelectionFeedbackGenerator?

    // MARK: UIControl

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let shouldBegin = super.beginTracking(touch, with: event)

        if shouldBegin {
            initialTrackingLocation = CGPoint(x: thumbRect.midX, y: thumbRect.midY)
            unadjustedValue = value
            feedbackGenerator = UISelectionFeedbackGenerator()
            feedbackGenerator?.prepare()
        }

        return shouldBegin
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard isTracking else { return false }

        let touchLocation = touch.location(in: self)
        let previousLocation = touch.previousLocation(in: self)

        let newSpeed = scrubbingSpeed(for: touchLocation, relativeTo: initialTrackingLocation)
        let valueAdjustment = self.valueAdjustment(for: touchLocation, relativeTo: previousLocation)
        let speedAdjustment = scrubbingSpeed * valueAdjustment
        let thumbAdjustment = self.thumbAdjustment(for: touchLocation, relativeToInitialLocation: initialTrackingLocation, previousLocation: previousLocation)

        previousSpeed = scrubbingSpeed
        scrubbingSpeed = newSpeed
        previousValue = value
        unadjustedValue += valueAdjustment
        value += speedAdjustment + thumbAdjustment

        if isContinuous {
            sendActions(for: .valueChanged)
        }

        generateFeedbackIfNecessary()

        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        resetScrubbingSpeed()
        feedbackGenerator = nil
        super.endTracking(touch, with: event)
    }

    override func cancelTracking(with event: UIEvent?) {
        resetScrubbingSpeed()
        feedbackGenerator = nil
        super.cancelTracking(with: event)
    }
}

// MARK: - Private

private extension ScrubbingSlider {

    var trackRect: CGRect {
        trackRect(forBounds: bounds)
    }

    var thumbRect: CGRect {
        thumbRect(forBounds: bounds, trackRect: trackRect, value: value)
    }

    func scrubbingSpeed(for touchLocation: CGPoint, relativeTo initialLocation: CGPoint) -> Float {
        scrubbingSpeed(forVerticalDistance: initialLocation.y - touchLocation.y)
    }

    func scrubbingSpeed(forVerticalDistance distance: CGFloat) -> Float {
        let distance = distance.clamped(to: scrubbingSpeeds.first!.verticalDistance, and: scrubbingSpeeds.last!.verticalDistance)
        let intervals = zip(scrubbingSpeeds, scrubbingSpeeds[1...])

        let matchedInterval = intervals.first {
            ($0.verticalDistance ..< $1.verticalDistance) ~= distance
        }

        return (matchedInterval?.0 ?? scrubbingSpeeds.last!).speed
    }

    func valueAdjustment(for touchLocation: CGPoint, relativeTo initialLocation: CGPoint) -> Float {
        valueAdjustment(forHorizontalDistance: touchLocation.x - initialLocation.x)
    }

    func valueAdjustment(forHorizontalDistance distance: CGFloat) -> Float {
        let relativeDistance = Float(distance / trackRect.width)
        let range = maximumValue - minimumValue
        return relativeDistance * range
    }

    /// The difference in value as a fraction of the vertical touch distance to the slider.
    ///
    /// Using scrubbing speeds, the horizontal positions of finger (unadjusted value) and
    /// handle (actual value) must not match. If the finger is moving towards the slider,
    /// the handle should move towards the slider such that both meet when the finger
    /// reaches the slider.
    func thumbAdjustment(for touchLocation: CGPoint, relativeToInitialLocation initialLocation: CGPoint, previousLocation: CGPoint) -> Float {
        let isMovingDown = (initialLocation.y < touchLocation.y) && (touchLocation.y < previousLocation.y)
        let isMovingUp = (initialLocation.y > touchLocation.y) && (touchLocation.y > previousLocation.y)

        guard isMovingDown || isMovingUp else { return 0 }

        let valueDistance = unadjustedValue - value
        let verticalDistance = Float(abs(touchLocation.y - initialLocation.y))

        return valueDistance / (1 + verticalDistance)
    }

    func resetScrubbingSpeed() {
        scrubbingSpeed = scrubbingSpeeds.first!.speed
    }

    func generateFeedbackIfNecessary() {
        let speedChanged = previousSpeed != scrubbingSpeed
        let minOrMaxReached = (previousValue != value) && ((value >= maximumValue) || (value <= minimumValue))

        guard speedChanged || minOrMaxReached else { return }

        feedbackGenerator?.selectionChanged()
        feedbackGenerator?.prepare()
    }
}

// MARK: - Util

private extension Comparable {
    func clamped(to lower: Self, and upper: Self) -> Self {
        assert(lower <= upper, "\(lower), \(upper)")
        return max(lower, min(upper, self))
    }
}
