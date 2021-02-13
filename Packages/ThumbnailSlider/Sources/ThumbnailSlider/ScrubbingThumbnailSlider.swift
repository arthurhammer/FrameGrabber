import CoreMedia
import UIKit

extension ScrubbingThumbnailSlider {

    /// The fraction of the default speed and the vertical distance at which it takes effect.
    public struct Speed: Hashable {
        public let speed: Float
        public let verticalDistance: CGFloat

        public static let defaultSpeeds = [
            Speed(speed: 1, verticalDistance: 0),
            Speed(speed: 0.5, verticalDistance: 70),
            Speed(speed: 0.25, verticalDistance: 120),
            Speed(speed: 0.1, verticalDistance: 170)
        ]

        public init(speed: Float, verticalDistance: CGFloat) {
            self.speed = speed
            self.verticalDistance = verticalDistance
        }
    }
}

/// A slider with variable scrubbing speeds.
public final class ScrubbingThumbnailSlider: ThumbnailSlider {

    public private(set) lazy var currentScrubbingSpeed = scrubbingSpeeds.first!

    /// The scrubbing speed configuration. Setting an empty array disables speeds.
    public var scrubbingSpeeds = Speed.defaultSpeeds {
        didSet {
            if scrubbingSpeeds.isEmpty {
                scrubbingSpeeds = [Speed.defaultSpeeds.first!]
            }

            scrubbingSpeeds.sort { $0.verticalDistance < $1.verticalDistance }
            resetScrubbingSpeed()
            
            adjustsHandleToMeetTouch = scrubbingSpeeds.count > 1
        }
    }
    
    /// Whether the handle should move towards the touch when the touch moves downwards towards the
    /// slider.
    private var adjustsHandleToMeetTouch = true

    /// `time` if it weren't adjusted for speed (i.e. where the touch actually is).
    private lazy var unadjustedTime = time
    private lazy var feedbackGenerator = UISelectionFeedbackGenerator()

    // MARK: - Tracking Touches

    override public func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let shouldBegin = super.beginTracking(touch, with: event)

        if shouldBegin {
            unadjustedTime = time
            feedbackGenerator.prepare()
        }

        return shouldBegin
    }

    override public func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let touchLocation = touch.location(in: self)
        let previousLocation = touch.previousLocation(in: self)

        let previousSpeed = currentScrubbingSpeed
        currentScrubbingSpeed = scrubbingSpeed(for: touchLocation)

        let previousTime = time
        let valueAdjustment = self.valueAdjustment(for: touchLocation, relativeTo: previousLocation)
        let speedAdjustment = CMTimeMultiplyByFloat64(
            valueAdjustment,
            multiplier: Float64(currentScrubbingSpeed.speed)
        )
        
        let handleAdjustment = adjustsHandleToMeetTouch
            ? self.handleAdjustment(for: touchLocation, relativeTo: previousLocation)
            : .zero

        unadjustedTime = unadjustedTime + valueAdjustment
        time = time + speedAdjustment + handleAdjustment

        sendActions(for: .valueChanged)

        generateFeedbackIfNecessary(forPreviousTime: previousTime, previousSpeed: previousSpeed)

        return true
    }

    override public func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        resetScrubbingSpeed()
    }

    override public func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
        resetScrubbingSpeed()
    }

    // MARK: - Private

    private func scrubbingSpeed(for touchLocation: CGPoint) -> Speed {
        return scrubbingSpeed(forVerticalDistance: bounds.midY - touchLocation.y)
    }

    private func scrubbingSpeed(forVerticalDistance distance: CGFloat) -> Speed {
        let distance = distance.clamped(
            to: scrubbingSpeeds.first!.verticalDistance,
            and: scrubbingSpeeds.last!.verticalDistance
        )

        let intervals = zip(scrubbingSpeeds, scrubbingSpeeds[1...])

        let matched = intervals.first {
            ($0.verticalDistance ..< $1.verticalDistance) ~= distance
        }

        return matched?.0 ?? scrubbingSpeeds.last!
    }

    private func valueAdjustment(
        for touchLocation: CGPoint,
        relativeTo initialLocation: CGPoint
    ) -> CMTime {

        valueAdjustment(forHorizontalDistance: touchLocation.x - initialLocation.x)
    }

    private func valueAdjustment(forHorizontalDistance distance: CGFloat) -> CMTime {
        let relativeDistance = distance / trackRect.width
        return CMTimeMultiplyByFloat64(duration, multiplier: Float64(relativeDistance))
            .numericOrZero
    }

    /// The difference in value as a fraction of the vertical touch distance to the slider.
    ///
    /// Using scrubbing speeds, the horizontal positions of finger (unadjusted value) and
    /// knob (actual value) must not match. If the finger is moving towards the slider,
    /// the knob should move towards the slider such that both meet when the finger
    /// reaches the slider.
    private func handleAdjustment(
        for touchLocation: CGPoint,
        relativeTo previousLocation: CGPoint
    ) -> CMTime {

        let isMovingDown = (bounds.midY < touchLocation.y) && (touchLocation.y < previousLocation.y)
        let isMovingUp = (bounds.midY > touchLocation.y) && (touchLocation.y > previousLocation.y)

        guard isMovingDown || isMovingUp else { return .zero }

        let valueDistance = unadjustedTime - time
        let verticalDistance = Float(abs(touchLocation.y - bounds.midY))
        let divisor = 1 / (1 + verticalDistance)

        return CMTimeMultiplyByFloat64(valueDistance, multiplier: Float64(divisor))
            .numericOrZero
    }

    private func resetScrubbingSpeed() {
        currentScrubbingSpeed = scrubbingSpeeds.first!
    }

    private func generateFeedbackIfNecessary(
        forPreviousTime previousTime: CMTime,
        previousSpeed: Speed
    ) {
        let speedChanged = previousSpeed != currentScrubbingSpeed
        let minOrMaxReached = (previousTime != time) && ((time >= duration) || (time <= .zero))

        if speedChanged || minOrMaxReached {
            feedbackGenerator.selectionChanged()
            feedbackGenerator.prepare()
        }
    }
}
