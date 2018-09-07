import UIKit

class ZoomAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    weak var from: ZoomAnimatable?
    weak var to: ZoomAnimatable?

    let type: TransitionType

    init(type: TransitionType, from: ZoomAnimatable?, to: ZoomAnimatable?) {
        self.type = type
        self.from = from
        self.to = to
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        switch type {
        case .present: return 0.4
        case .dismiss: return 0.2
        }
    }

    func animateTransition(using context: UIViewControllerContextTransitioning) {
        switch type {
        case .present: animatePresentation(using: context)
        case .dismiss: animateDismissal(using: context)
        }
    }
}

private extension ZoomAnimator {

    func animatePresentation(using context: UIViewControllerContextTransitioning) {
        // For correct frames, install and lay out views first.
        context.installViewsInContainer(for: type)

        willBegin()

        guard let image = from?.zoomAnimatorImage(self) ?? to?.zoomAnimatorImage(self),
            let fromImageFrame = from?.zoomAnimator(self, imageFrameInView: context.containerView),
            let toImageFrame = to?.zoomAnimator(self, imageFrameInView: context.containerView)
        else {
            // Can't animate image, use fallback animation.
            animateCrossDissolve(using: context)
            return
        }

        let duration = transitionDuration(using: context)
        let transitionImageView = self.transitionImageView(with: image, frame: fromImageFrame)
        context.containerView.addSubview(transitionImageView)
        context.toView?.alpha = 0

        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {

            transitionImageView.frame = toImageFrame
            context.toView?.alpha = 1

        }, completion: { _ in

            transitionImageView.removeFromSuperview()
            context.completeTransition(!context.transitionWasCancelled)
            self.didEnd()

        })
    }

    func animateDismissal(using context: UIViewControllerContextTransitioning) {
        context.installViewsInContainer(for: type)

        willBegin()

        guard let image = from?.zoomAnimatorImage(self) ?? to?.zoomAnimatorImage(self),
            let fromImageFrame = from?.zoomAnimator(self, imageFrameInView: context.containerView),
            let toImageFrame = to?.zoomAnimator(self, imageFrameInView: context.containerView)
        else {
            animateCrossDissolve(using: context)
            return
        }

        let duration = transitionDuration(using: context)
        let transitionImageView = self.transitionImageView(with: image, frame: fromImageFrame)
        context.containerView.addSubview(transitionImageView)

        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {

            transitionImageView.frame = toImageFrame
            context.fromView?.alpha = 0

        }, completion: { _ in

            transitionImageView.removeFromSuperview()
            context.completeTransition(!context.transitionWasCancelled)
            self.didEnd()

        })
    }

    // Assumes views are already installed.
    func animateCrossDissolve(using context: UIViewControllerContextTransitioning) {
        let presented = (type == .present) ? context.toView : context.fromView
        let fromAlpha: CGFloat = (type == .present) ? 0 : 1
        let toAlpha: CGFloat = (type == .present) ? 1 : 0

        presented?.alpha = fromAlpha

        UIView.animate(withDuration: transitionDuration(using: context), delay: 0, options: .transitionCrossDissolve, animations: {
            presented?.alpha = toAlpha
        }, completion: { _ in
            context.completeTransition(!context.transitionWasCancelled)
            self.didEnd()
        })
    }

    func transitionImageView(with image: UIImage, frame: CGRect) -> UIImageView {
        let imageView = UIImageView(frame: frame)
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }

    func willBegin() {
        from?.zoomAnimatorAnimationWillBegin(self)
        to?.zoomAnimatorAnimationWillBegin(self)
    }

    func didEnd () {
        from?.zoomAnimatorAnimationDidEnd(self)
        to?.zoomAnimatorAnimationDidEnd(self)
    }
}
