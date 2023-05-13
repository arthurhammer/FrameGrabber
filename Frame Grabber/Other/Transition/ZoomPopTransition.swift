import UIKit

/// An interactive and non-interactive animated pop transition.
class ZoomPopTransition: NSObject, ZoomTransition, UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning  {

    let type: TransitionType = .pop

    private(set) weak var fromDelegate: ZoomTransitionDelegate?
    private(set) weak var toDelegate: ZoomTransitionDelegate?
    
    init(from: ZoomTransitionDelegate?, to: ZoomTransitionDelegate?) {
        self.fromDelegate = from
        self.toDelegate = to
        super.init()
    }

    /// You can use this flag to track whether the transition should be started
    /// interactively.
    var wantsInteractiveStart = false

    private var transitionContext: UIViewControllerContextTransitioning?
    /// Runs additional animations in sync with the main pan and release animations.
    /// You can use `animate(alongsideTransition:completion:)` to add your own animations.
    private var backgroundAnimator: UIViewPropertyAnimator?
    private var gestureEndedBeforeTransitionStarted = false

    /// View that will be animated (not `context.fromView`).
    private var sourceView: UIView?
    private var initialSourceFrameWithoutTransform: CGRect = .zero
    private var initialSourceTransform: CGAffineTransform = .identity

    private let minimumImageScale: CGFloat = 0.68
    private let maximumVerticalDrag: CGFloat = 300
    private let minimumProgressToComplete: CGFloat = 0.1

    typealias AnimationParameters = (duration: TimeInterval, damping: CGFloat)
    private let completionParameters: AnimationParameters = (0.37, 0.90)
    private let cancelParameters: AnimationParameters = (0.45, 0.75)
    private let fallbackParameters: AnimationParameters = (0.50, 0.90)

    /// Required by `UIViewControllerAnimatedTransitioning` for the non-interactive
    /// transition.
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        completionParameters.duration
    }

    // MARK: Entry Points

    /// Starts the interactive transition. This is the entry point for the interactive pop
    /// transition (`UIViewControllerInteractiveTransitioning`, called by the system in
    /// response to `popViewController`.
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        // In rare cases, the pan gesture state can go from `began` to `ended` before
        // `startInteractiveTransition` is even called.
        guard !gestureEndedBeforeTransitionStarted else {
            DispatchQueue.main.async {
                transitionContext.cancelInteractiveTransition()
                transitionContext.completeTransition(false)
            }
            return
        }

        gestureEndedBeforeTransitionStarted = false

        prepareTransition(using: transitionContext)
    }

    /// Starts the non-interactive transition. This is the entry point for the
    /// non-interactive pop transition (`UIViewControllerAnimatedTransitioning`), called
    /// by the system in response to `popViewController`.
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        prepareTransition(using: transitionContext)
        startNonInteractiveAnimation(using: transitionContext)
    }

    /// Prepares the container view, sets up the view hierarchy, initializes states and
    /// notifies delegates the transition is about to begin.
    private func prepareTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let sourceView = fromDelegate?.zoomTransitionView(self) else {
            // todo: Use rudamentary fallback transition instead of crashing.
            fatalError("A source view to animate from is required for the transition.")
        }

        self.transitionContext = transitionContext
        transitionContext.installViewsInContainer(for: type)

        self.sourceView = sourceView
        initialSourceFrameWithoutTransform = sourceView.originalFrameWithoutTransform
        initialSourceTransform = sourceView.transform

        backgroundAnimator = UIViewPropertyAnimator(duration: 1, dampingRatio: 1, animations: nil)
        transitionWillBegin()
    }

    // MARK: Interactive Transition

    /// Updates the interactive transition from the pan gesture. Typically called by the
    /// client that owns the pan gesture.
    ///
    /// Moves and scales the animation view and updates the background animations.
    /// When the gesture ends, completes the transition via the non-interactive animation.
    func updateInteractiveTransition(for gesture: UIPanGestureRecognizer) {
        // We are not inside a valid transition.
        guard let transitionContext else {
            gestureEndedBeforeTransitionStarted = gesture.state == .ended
            return
        }

        let translation = gesture.translation(in: gesture.view)
        let progress = fractionComplete(forVerticalDrag: translation.y, maximumDrag: maximumVerticalDrag)
        let imageScale = transitionImageScaleFor(percentageComplete: progress, minimumScale: minimumImageScale)

        switch gesture.state {

        case .changed:
            sourceView?.transform = initialSourceTransform.adjusted(withTranslation: translation, scale: imageScale)
            backgroundAnimator?.fractionComplete = progress
            transitionContext.updateInteractiveTransition(progress)

        case .cancelled, .failed:
            finishInteractiveTransition(didCancel: true)
            startNonInteractiveAnimation(using: transitionContext)

        case .ended:
            let isMovingDown = gesture.velocity(in: gesture.view).y > 0
            let didMakeProgress = progress > minimumProgressToComplete
            let shouldComplete = isMovingDown && didMakeProgress

            finishInteractiveTransition(didCancel: !shouldComplete)
            startNonInteractiveAnimation(using: transitionContext)

        default:
            break
        }
    }

    /// Registers the successful finish or the cancellation of the interactive part of the
    /// transition.
    private func finishInteractiveTransition(didCancel: Bool) {
        if didCancel {
             transitionContext?.cancelInteractiveTransition()
        } else {
             transitionContext?.finishInteractiveTransition()
        }
    }

    // MARK: Non-Interactive Transition

    /// Starts the final non-interactive animations of all participating views to their
    /// final locations (depending on whether the transition was completed or cancelled).
    /// Registers the completion of the entire transition, cleans up and restores states
    /// and notifies delegates about the completion.
    private func startNonInteractiveAnimation(using transitionContext: UIViewControllerContextTransitioning) {
        // We are not inside a valid transition.
        guard let backgroundAnimator else { return }

        // Sync up both animators.
        let foregroundAnimator = nonInteractiveAnimator(using: transitionContext)
        let durationFactor = CGFloat(foregroundAnimator.duration / backgroundAnimator.duration)

        foregroundAnimator.startAnimation()
        
        // Is still inactive for non-interactive transitions. Activate keeping current progress.
        let fractionComplete = backgroundAnimator.fractionComplete
        backgroundAnimator.fractionComplete = fractionComplete
        
        backgroundAnimator.isReversed = transitionContext.transitionWasCancelled
        backgroundAnimator.continueAnimation(withTimingParameters: nil, durationFactor: durationFactor)
    }

    /// An animator that implements the final non-interactive animations of all
    /// participating views. The animator can be used for both the interactive and the
    /// non-interactive transition.
    ///
    /// On completion of the animations, cleans up and restores states, registers the
    /// completion of the entire transition and notifies delegates.
    private func nonInteractiveAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewPropertyAnimator {
        // We are not inside a valid transition.
        guard let sourceView else {
            fatalError("A source view to animate from is required for the transition.")
        }

        let didCancel = transitionContext.transitionWasCancelled

        let containerView = transitionContext.containerView
        let animations: () -> ()
        let parameters: (duration: TimeInterval, damping: CGFloat)
        var transitionView = UIView()  // dummy.

        // Cancelled: Animate back into original position.
        if didCancel {
            parameters = cancelParameters

            animations = {
                sourceView.transform = self.initialSourceTransform
            }
        // Completed: Animate into final position (cross-fading with the target view).
        } else if let targetView = toDelegate?.zoomTransitionView(self),
            let fromView = transitionContext.fromView {

            transitionView = targetView.transitionView()
            let currentFrame = sourceView.currentFrameWithoutTransform
            let targetFrame = containerView.convert(targetView.frame, from: targetView.superview)

            // We are switching over to using frames directly over transforms. This allows
            // the source view to layout dynamically based on its content mode (e.g.
            // aspect filling the player view) instead of being distorted by the transform
            // into the final target frame.
            sourceView.transform = .identity
            sourceView.frame = currentFrame
            sourceView.layoutIfNeeded()

            transitionView.frame = containerView.convert(currentFrame, from: sourceView.superview)
            containerView.insertSubview(transitionView, belowSubview: fromView)

            parameters = completionParameters

            animations = {
                fromView .alpha = 0
                sourceView.frame = containerView.convert(targetFrame, to: sourceView.superview)
                transitionView.frame = targetFrame
            }
        // Completed but no target view exists (e.g. cell deleted): Shrink into its center.
        } else {
            parameters = fallbackParameters
            
            animations = {
                sourceView.transform = sourceView.transform.scaledBy(x: 0.01, y: 0.01)
                sourceView.alpha = 0
            }
        }

        let foregroundAnimator = UIViewPropertyAnimator(duration: parameters.duration, dampingRatio: parameters.damping, animations: animations)

        // Complete transition, restore state, notifiy delegates.
        foregroundAnimator.addCompletion { _ in
            transitionView.removeFromSuperview()

            sourceView.transform = .identity  // Required.
            sourceView.frame = self.initialSourceFrameWithoutTransform
            sourceView.transform = self.initialSourceTransform
            sourceView.alpha = 1

            self.transitionContext = nil
            self.backgroundAnimator = nil
            self.sourceView = nil
            self.initialSourceFrameWithoutTransform = .zero
            self.initialSourceTransform = .identity
            self.wantsInteractiveStart = false 

            self.transitionDidEnd()
            transitionContext.completeTransition(!didCancel)
        }

        return foregroundAnimator
    }

    // MARK: Other

    func animate(alongsideTransition animation: @escaping (UIViewControllerContextTransitioning) -> (), completion: ((UIViewControllerContextTransitioning) -> ())? = nil) {
        guard let transitionContext else { return }

        backgroundAnimator?.addAnimations {
            animation(transitionContext)
        }

        backgroundAnimator?.addCompletion { _ in
            completion?(transitionContext)
        }
    }
}

// MARK: - Util

private extension ZoomPopTransition {

    func fractionComplete(forVerticalDrag verticalDrag: CGFloat, maximumDrag: CGFloat) -> CGFloat {
        max(0, min(verticalDrag / maximumDrag, 1))
    }

    func transitionImageScaleFor(percentageComplete: CGFloat, minimumScale: CGFloat) -> CGFloat {
        1 - (1 - minimumScale) * percentageComplete
    }
}
