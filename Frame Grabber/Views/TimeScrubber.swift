import UIKit

// Portions adapted from OBSlider (Ole Begemann, MIT License, https://github.com/ole/OBSlider)

/// A slider that allows sliding anywhere on its track and has variable sliding speeds.
public class ScrubbingSlider: UISlider {

    /// The vertical distance from the slider at which the corresponding speed starts to take effect.
    ///  A speed of `1.0` is the normal scrubbing speed, `0.5` is half as fast and so on.
    public typealias SpeedStop = (verticalOffset: CGFloat, speed: Float)

    /// Currently, variable speeds are only supported in the negative `y` direction (above the slider).
    /// Scrubbing below the slider uses the default speed.
    public var speedStops: [SpeedStop] = [(0, 1), (50, 0.5), (100, 0.25), (150, 0.1)] {
        didSet {
            if speedStops.isEmpty {
                speedStops = [(0, 1)]
            }
            speedStops.sort { $0.verticalOffset < $1.verticalOffset }
        }
    }

    /// The current scrubbing speed.
    public private(set) lazy var scrubbingSpeed = speedStops.first!.speed

    // MARK: - UIControl

    override public func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        initialTrackingLocation = touch.location(in: self)
        return true  // Allow sliding anywhere in the slider
    }

    override public func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let (change, speed) = valueChangeAndSpeed(for: touch, initialTrackingLocation: initialTrackingLocation)

        scrubbingSpeed = speed
        value += change

        if isContinuous {
            sendActions(for: .valueChanged)
        }

        return true
    }

    override public func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        // Ugly hack.
        // Super call is required (cf. docs) but super implementation adjusts slider
        // value to thumb position. Can revert the value after super call but
        // still leads to UI flickering.
        // Tried overwriting `sendActions(for controlEvents)` to filter for the event
        // but is not called (the super's implementation is called instead).
        // Hack: Detach and restore value changed targets.
        detachTargetActionsAndSaveValue()
        super.endTracking(touch, with: event)
        attachTargetActionsAndRestoreValue()

        if let touch = touch {
            let (change, _) = valueChangeAndSpeed(for: touch, initialTrackingLocation: initialTrackingLocation)
            value += change
        }

        scrubbingSpeed = speedStops.first!.speed
        sendActions(for: .valueChanged)
    }

    override public func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
        scrubbingSpeed = speedStops.first!.speed
    }

    // MARK: - Private

    private var initialTrackingLocation: CGPoint = .zero

    private var trackWidth: CGFloat {
        return trackRect(forBounds: bounds).width
    }

    private func valueChangeAndSpeed(for touch: UITouch, initialTrackingLocation: CGPoint) -> (valueChange: Float, speed: Float) {
        let previousLocation = touch.previousLocation(in: self)
        let currentLocation = touch.location(in: self)

        let horizontalOffset = currentLocation.x - previousLocation.x  // from previous touch
        let verticalOffset = initialTrackingLocation.y - currentLocation.y  // from track

        let relativeHorizontalOffset = Float(horizontalOffset / trackWidth)
        let scrubbingSpeed = speed(for: verticalOffset)
        let sliderRange = maximumValue - minimumValue

        let valueChange = scrubbingSpeed * relativeHorizontalOffset * sliderRange

        return (valueChange, scrubbingSpeed)
    }

    private func speed(for verticalOffset: CGFloat) -> Float {
        let offset = verticalOffset.clamped(to: speedStops.first!.verticalOffset, and: speedStops.last!.verticalOffset)
        let speedIntervals = zip(speedStops, speedStops[1...])

        let matchedInterval = speedIntervals.first {
            ($0.verticalOffset ..< $1.verticalOffset) ~= offset
        }

        return (matchedInterval?.0 ?? speedStops.last!).speed
    }

    // Hack
    private var targetActions = [TargetAction]()
    private var previousValue: Float = 0

    private func detachTargetActionsAndSaveValue() {
        previousValue = value
        targetActions = targetActions(for: .valueChanged)
        remove(targetActions: targetActions, for: .valueChanged)
    }

    private func attachTargetActionsAndRestoreValue() {
        add(targetActions: targetActions, for: .valueChanged)
        targetActions = []
        value = previousValue
    }
}

// MARK: - Util

private extension Comparable {
    func clamped(to lower: Self, and upper: Self) -> Self {
        assert(lower <= upper, "\(lower), \(upper)")
        return max(lower, min(upper, self))
    }
}

// Hack
private extension UIControl {
    typealias TargetAction = (target: AnyHashable, action: Selector)

    func targetActions(for controlEvent: UIControlEvents) -> [TargetAction] {
        var result = [TargetAction]()

        allTargets.forEach { target in
            guard let actions = actions(forTarget: target, forControlEvent: controlEvent) else { return }
            result.append(contentsOf: actions.map { (target, NSSelectorFromString($0)) })
        }

        return result
    }

    func remove(targetActions: [TargetAction], for controlEvent: UIControlEvents) {
        targetActions.forEach {
            removeTarget($0, action: $1, for: controlEvent)
        }
    }

    func add(targetActions: [TargetAction], for controlEvent: UIControlEvents) {
        targetActions.forEach {
            addTarget($0, action: $1, for: controlEvent)
        }
    }
}
