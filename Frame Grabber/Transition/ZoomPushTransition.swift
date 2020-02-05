import UIKit

/// A non-interactive, animated push transition.
class ZoomPushTransition: NSObject, ZoomTransition, UIViewControllerAnimatedTransitioning {

    let type: TransitionType = .push
    
    weak var fromDelegate: ZoomTransitionDelegate?
    weak var toDelegate: ZoomTransitionDelegate?

    private var transitionContext: UIViewControllerContextTransitioning?
    private var animator: UIViewPropertyAnimator?

    private let duration: TimeInterval = 0.45
    private let damping: CGFloat = 0.75
    private let crossDissolveDuration: TimeInterval = 0.3

    init(from: ZoomTransitionDelegate?, to: ZoomTransitionDelegate?) {
        self.fromDelegate = from
        self.toDelegate = to
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        duration
    }

    func animateTransition(using context: UIViewControllerContextTransitioning) {
        configureAnimator(using: context).startAnimation()
    }

    /// Sets up the entire transition including container view, animation details and
    /// completion registration. Returns an (inactive) animator.
    private func configureAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewPropertyAnimator {
        if let animator = animator { return animator }

        transitionContext.installViewsInContainer(for: type)

        let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: damping)

        self.transitionContext = transitionContext
        self.animator = animator

        // Context and animator instance variables need to be set before this is called
        // so the client can use `animate(alongsideTransition:completion:)` inside.
        transitionWillBegin()

        guard let sourceView = fromDelegate?.zoomTransitionView(self),
            let targetView = toDelegate?.zoomTransitionView(self) else {

                fatalError("Source and target views to animate between are required for the transition.")
        }

        let containerView = transitionContext.containerView
        let transitionView = sourceView.transitionView()

        let startingFrame = containerView.convert(sourceView.frame, from: sourceView.superview)
        let targetFrame = containerView.convert(targetView.frame, from: targetView.superview)

        transitionView.frame = startingFrame
        containerView.addSubview(transitionView)
        transitionContext.toView?.alpha = 0
        targetView.isHidden = true

        animator.addAnimations {
            transitionView.frame = targetFrame
            transitionContext.toView?.alpha = 1
        }

        animator.addCompletion { _ in
            targetView.isHidden = false

            UIView.animate(withDuration: self.crossDissolveDuration, animations: {
                transitionView.alpha = 0
            }, completion: { _ in
                transitionView.removeFromSuperview()
            })

            self.transitionContext = nil
            self.animator = nil

            self.transitionDidEnd()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }

        return animator
    }

    func animate(alongsideTransition animation: @escaping (UIViewControllerContextTransitioning) -> (), completion: ((UIViewControllerContextTransitioning) -> ())?) {
        guard let transitionContext = transitionContext else { return }

        animator?.addAnimations {
            animation(transitionContext)
        }

        animator?.addCompletion { _ in
            completion?(transitionContext)
        }
    }
}
