import UIKit

extension UIViewControllerContextTransitioning {
    
    var fromView: UIView? {
        view(forKey: .from)
    }

    var toView: UIView? {
        view(forKey: .to)
    }

    var finalToFrame: CGRect? {
        viewController(forKey: .to).flatMap(finalFrame)
    }

    func installViewsInContainer(for type: TransitionType) {
        // toView is nil if already in container, i.e. for dismissals where presenter
        // remained in view hierarchy.
        if let toView {
            toView.frame = finalToFrame ?? .zero

            if type == .pop, let fromView = fromView {
                containerView.insertSubview(toView, belowSubview: fromView)
            } else {
                containerView.addSubview(toView)
            }
        }

        containerView.layoutIfNeeded()        
    }
}

extension UIView {

    /// The frame of the view with an identity transform.
    var originalFrameWithoutTransform: CGRect {
        CGRect(x: center.x - bounds.width/2,
               y: center.y - bounds.height/2,
               width: bounds.width,
               height: bounds.height)
    }

    /// A rectangle describing the current position and size of the view in the superview's
    /// coordinate system taking into account its current transform.
    /// - note: http://macoscope.com/blog/understanding-frame/
    var currentFrameWithoutTransform: CGRect {
        var rect = CGRect(x: -bounds.width * layer.anchorPoint.x,
                          y: -bounds.height * layer.anchorPoint.y,
                          width: bounds.width,
                          height: bounds.height)

        rect = rect.applying(transform)
        rect.origin.x += center.x
        rect.origin.y += center.y

        return rect
    }

    /// A view to animate in place of the receiver. If the receiver is an `UIImageView`,
    /// the return value is an image view containing its image. Otherwise it is a snapshot
    /// view of the receiver or, if none could be created, a solid gray plain view.
    func transitionView() -> UIView {
        if let imageView = self as? UIImageView {
            let transitionImageView = UIImageView(frame: imageView.frame)
            transitionImageView.image = imageView.image
            transitionImageView.contentMode = imageView.contentMode
            transitionImageView.clipsToBounds = true
            return transitionImageView
        }

        if let snapshotView = self.snapshotView(afterScreenUpdates: true) {
            snapshotView.contentMode = .scaleAspectFill
            snapshotView.clipsToBounds = true
            return snapshotView
        }

        let fallbackView = UIView(frame: frame)
        fallbackView.backgroundColor = .systemGray4
        return fallbackView
    }
}


extension CGAffineTransform {

    /// The current scale.
    var scale: CGPoint {
        CGPoint(x: sqrt(a*a + c*c),
                y: sqrt(b*b + d*d))
    }

    /// Applying a transform where the translation is scaled with the current scale.
    func adjusted(withTranslation translation: CGPoint, scale: CGFloat) -> CGAffineTransform {
        var baseScale = self.scale

        if baseScale.x == 0 {
            baseScale.x = 1
        }
        
        if baseScale.y == 0 {
            baseScale.y = 1
        }

        return translatedBy(x: translation.x / baseScale.x, y: translation.y / baseScale.y)
            .scaledBy(x: scale, y: scale)
    }
}

