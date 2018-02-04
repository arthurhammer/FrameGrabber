//import UIKit
//
//extension UIView {
//
//    func fadeIn(withDuration duration: TimeInterval = 0.2, options: UIViewAnimationOptions = .curveEaseIn, completion: ((Bool) -> ())? = nil) {
//        fade(to: 1, withDuration: duration, options: options, completion: completion)
//    }
//
//    func fadeOut(withDuration duration: TimeInterval = 0.2, options: UIViewAnimationOptions = .curveEaseIn, completion: ((Bool) -> ())? = nil) {
//        fade(to: 0, withDuration: duration, options: options, completion: completion)
//    }
//
//    func fade(to: CGFloat, from: CGFloat? = nil, withDuration duration: TimeInterval = 0.2, options: UIViewAnimationOptions = .curveEaseIn, completion: ((Bool) -> ())? = nil) {
//        if let from = from {
//            alpha = from
//        }
//
//        isHidden = false
//
//        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
//            self.alpha = to
//        }, completion: completion)
//    }
//}
//
