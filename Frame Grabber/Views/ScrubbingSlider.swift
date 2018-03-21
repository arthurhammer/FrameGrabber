// Portions adapted from OBSlider:
//     Ole Begemann, MIT License, https://github.com/ole/OBSlider

import UIKit

/// A slider that allows sliding anywhere on its track and has variable sliding speeds.
class ScrubbingSlider: UISlider {

    /// The vertical distance from the slider at which the corresponding speed starts to
    /// take effect. A speed of `1.0` is the normal scrubbing speed, `0.5` is half as fast
    /// etc.
    typealias ScrubbingSpeed = (verticalOffset: CGFloat, speed: Float)

    /// Currently, variable speeds are only supported in the negative `y` direction (above
    /// the slider). Scrubbing below the slider always uses the default speed.
    var scrubbingSpeeds: [ScrubbingSpeed] = [(0, 1), (50, 0.5), (100, 0.25), (150, 0.1)] {
        didSet {
            let defaultSpeed = [ScrubbingSpeed(0, 1)]
            scrubbingSpeeds = scrubbingSpeeds.isEmpty ? defaultSpeed : scrubbingSpeeds
            scrubbingSpeeds.sort { $0.verticalOffset < $1.verticalOffset }
        }
    }

    private(set) lazy var currentScrubbingSpeed = scrubbingSpeeds.first!.speed

    // MARK: UIControl

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        didDrag = false
        initialTouchPoint = touch.location(in: self)
        return true  // Allow sliding anywhere in the slider
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        didDrag = true

        currentScrubbingSpeed = scrubbingSpeed(for: touch, initialTouchPoint: initialTouchPoint)
        value += changeInValueFromPreviousTouch(for: touch, scrubbingSpeed: currentScrubbingSpeed)

        if isContinuous {
            sendActions(for: .valueChanged)
        }

        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        // Ignore taps
        guard didDrag else { return }

        // Hack.
        //
        // The super implementation (which we are required to call, see docs) moves thumb
        // and value to the final touch position. We want thumb/value to remain unchanged.
        // Reverting the value after the super call leads to UI flickering and wrong
        // value-changed events.
        // Overwriting `sendActions(for controlEvents)` to filter for the value-changed
        // event doesn't work as the the super but not the overwritten implementation is
        // called.
        //
        // Solution: Detach and restore target-actions so we don't send wrong values.
        detachTargetActionsAndSaveValue()
        super.endTracking(touch, with: event)
        attachTargetActionsAndRestoreValue()

        if let touch = touch {
            currentScrubbingSpeed = scrubbingSpeed(for: touch, initialTouchPoint: initialTouchPoint)
            value += changeInValueFromPreviousTouch(for: touch, scrubbingSpeed: currentScrubbingSpeed)
        }

        resetScrubbingSpeed()
        sendActions(for: .valueChanged)
    }

    override func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
        resetScrubbingSpeed()
    }

    // MARK: Private Properties

    private var initialTouchPoint: CGPoint = .zero
    var didDrag = false

    private var trackWidth: CGFloat {
        return trackRect(forBounds: bounds).width
    }

    private var targetActions = [TargetAction]()
    private var previousValue: Float = 0
}

// MARK: - Private

private extension ScrubbingSlider {

    func changeInValueFromPreviousTouch(for touch: UITouch, scrubbingSpeed: Float) -> Float {
        let changeInTouch = touch.location(in: self).x - touch.previousLocation(in: self).x
        let relativeChangeInTouch = Float(changeInTouch / trackWidth)
        let valueRange = maximumValue - minimumValue
        let changeInValue = relativeChangeInTouch * valueRange

        return scrubbingSpeed * changeInValue
    }

    func scrubbingSpeed(for touch: UITouch, initialTouchPoint: CGPoint) -> Float {
        let verticalOffset = initialTouchPoint.y - touch.location(in: self).y
        return scrubbingSpeed(for: verticalOffset)
    }

    func scrubbingSpeed(for verticalOffset: CGFloat) -> Float {
        let offset = verticalOffset.clamped(to: scrubbingSpeeds.first!.verticalOffset, and: scrubbingSpeeds.last!.verticalOffset)
        let speedIntervals = zip(scrubbingSpeeds, scrubbingSpeeds[1...])

        let matchedInterval = speedIntervals.first {
            ($0.verticalOffset ..< $1.verticalOffset) ~= offset
        }

        return (matchedInterval?.0 ?? scrubbingSpeeds.last!).speed
    }

    func resetScrubbingSpeed() {
        currentScrubbingSpeed = scrubbingSpeeds.first!.speed
    }

    func detachTargetActionsAndSaveValue() {
        previousValue = value
        targetActions = targetActions(for: .valueChanged)
        remove(targetActions: targetActions, for: .valueChanged)
    }

    func attachTargetActionsAndRestoreValue() {
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

private extension UIControl {

    typealias TargetAction = (target: Any, action: Selector)

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
