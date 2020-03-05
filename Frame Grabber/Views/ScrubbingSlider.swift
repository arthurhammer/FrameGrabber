import UIKit

// MARK: - ScrubbingSpeed

/// The fraction of the default speed and the vertical distance at which it takes effect.
struct ScrubbingSpeed: Hashable {
    let speed: Float
    let verticalDistance: CGFloat
}

extension ScrubbingSpeed {
    static let defaultSpeeds = [
        ScrubbingSpeed(speed: 1, verticalDistance: 0),
        ScrubbingSpeed(speed: 0.5, verticalDistance: 70),
        ScrubbingSpeed(speed: 0.25, verticalDistance: 120),
        ScrubbingSpeed(speed: 0.1, verticalDistance: 170)
    ]
}

// MARK: - ScrubbingSlider

/// A slider with variable scrubbing speeds.
class ScrubbingSlider: UISlider {

    private(set) lazy var currentScrubbingSpeed = scrubbingSpeeds.first!

    /// The scrubbing speed configuration. Setting an empty array disables speeds.
    var scrubbingSpeeds = ScrubbingSpeed.defaultSpeeds {
        didSet {
            if scrubbingSpeeds.isEmpty {
                scrubbingSpeeds = [ScrubbingSpeed.defaultSpeeds.first!]
            }

            scrubbingSpeeds.sort { $0.verticalDistance < $1.verticalDistance }
        }
    }

    /// `value` if it weren't adjusted for speed (i.e. where the finger actually is).
    private lazy var unadjustedValue = value
    private lazy var feedbackGenerator = UISelectionFeedbackGenerator()

    // MARK: UIControl

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let shouldBegin = super.beginTracking(touch, with: event)

        if shouldBegin {
            unadjustedValue = value
            feedbackGenerator.prepare()
        }

        return shouldBegin
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard isTracking else { return false }

        let touchLocation = touch.location(in: self)
        let previousLocation = touch.previousLocation(in: self)

        let previousSpeed = currentScrubbingSpeed
        currentScrubbingSpeed = scrubbingSpeed(for: touchLocation)

        let previousValue = value
        let valueAdjustment = self.valueAdjustment(for: touchLocation, relativeTo: previousLocation)
        let speedAdjustment = currentScrubbingSpeed.speed * valueAdjustment
        let thumbAdjustment = self.thumbAdjustment(for: touchLocation, relativeTo: previousLocation)

        unadjustedValue = unadjustedValue + valueAdjustment
        value = value + speedAdjustment + thumbAdjustment

        if isContinuous {
            sendActions(for: .valueChanged)
        }

        generateFeedbackIfNecessary(forPreviousValue: previousValue, previousSpeed: previousSpeed)

        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        resetScrubbingSpeed()
        super.endTracking(touch, with: event)
    }

    override func cancelTracking(with event: UIEvent?) {
        resetScrubbingSpeed()
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

    func scrubbingSpeed(for touchLocation: CGPoint) -> ScrubbingSpeed {
        return scrubbingSpeed(forVerticalDistance: thumbRect.midY - touchLocation.y)
    }

    func scrubbingSpeed(forVerticalDistance distance: CGFloat) -> ScrubbingSpeed {
        let distance = distance.clamped(to: scrubbingSpeeds.first!.verticalDistance, and: scrubbingSpeeds.last!.verticalDistance)
        let intervals = zip(scrubbingSpeeds, scrubbingSpeeds[1...])

        let matchedInterval = intervals.first {
            ($0.verticalDistance ..< $1.verticalDistance) ~= distance
        }

        return matchedInterval?.0 ?? scrubbingSpeeds.last!
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
    /// knob (actual value) must not match. If the finger is moving towards the slider,
    /// the knob should move towards the slider such that both meet when the finger
    /// reaches the slider.
    func thumbAdjustment(for touchLocation: CGPoint, relativeTo previousLocation: CGPoint) -> Float {
        let isMovingDown = (thumbRect.midY < touchLocation.y) && (touchLocation.y < previousLocation.y)
        let isMovingUp = (thumbRect.midY > touchLocation.y) && (touchLocation.y > previousLocation.y)

        guard isMovingDown || isMovingUp else { return 0 }

        let valueDistance = unadjustedValue - value
        let verticalDistance = Float(abs(touchLocation.y - thumbRect.midY))

        return valueDistance / (1 + verticalDistance)
    }

    func resetScrubbingSpeed() {
        currentScrubbingSpeed = scrubbingSpeeds.first!
    }

    func generateFeedbackIfNecessary(forPreviousValue previousValue: Float, previousSpeed: ScrubbingSpeed) {
        let speedChanged = previousSpeed != currentScrubbingSpeed
        let minOrMaxReached = (previousValue != value) && ((value >= maximumValue) || (value <= minimumValue))

        if speedChanged || minOrMaxReached {
            feedbackGenerator.selectionChanged()
            feedbackGenerator.prepare()
        }
    }
}

private extension Comparable {
    func clamped(to lower: Self, and upper: Self) -> Self {
        assert(lower <= upper, "\(lower), \(upper)")
        return max(lower, min(upper, self))
    }
}
