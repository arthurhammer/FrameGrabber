import UIKit

protocol ZoomAnimatable: class {
    func zoomAnimatorAnimationWillBegin(_ animator: ZoomAnimator)
    func zoomAnimatorImage(_ animator: ZoomAnimator) -> UIImage?
    func zoomAnimator(_ animator: ZoomAnimator, imageFrameInView view: UIView) -> CGRect?
    func zoomAnimatorAnimationDidEnd(_ animator: ZoomAnimator)
}

extension ZoomAnimatable {
    func zoomAnimatorAnimationWillBegin(_ animator: ZoomAnimator) {}
    func zoomAnimatorAnimationDidEnd(_ animator: ZoomAnimator) {}
}
