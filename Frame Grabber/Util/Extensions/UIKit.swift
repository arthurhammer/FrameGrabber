import UIKit

extension UIApplication {
    
    /// Open the app's settings in Settings.
    func openSettings(completionHandler: ((Bool) -> ())? = nil) {
        guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString),
            canOpenURL(settingsUrl) else {

            completionHandler?(false)
            return
        }

        open(settingsUrl, options: [:], completionHandler: completionHandler)
    }
}

extension UIView {

    func fadeIn(withDuration duration: TimeInterval = 0.2, options: UIViewAnimationOptions = .curveEaseIn, completion: ((Bool) -> ())? = nil) {
        fade(to: 1, withDuration: duration, options: options, completion: completion)
    }

    func fadeOut(withDuration duration: TimeInterval = 0.2, options: UIViewAnimationOptions = .curveEaseIn, completion: ((Bool) -> ())? = nil) {
        fade(to: 0, withDuration: duration, options: options, completion: completion)
    }

    func fade(to: CGFloat, from: CGFloat? = nil, withDuration duration: TimeInterval = 0.2, options: UIViewAnimationOptions = .curveEaseIn, completion: ((Bool) -> ())? = nil) {
        if let from = from {
            alpha = from
        }

        isHidden = false

        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            self.alpha = to
        }, completion: completion)
    }
}

extension UICollectionView {
    func clearSelection() {
        selectItem(at: nil, animated: true, scrollPosition: .top)
    }
}

extension UIColor {

    /// A color from RGB integer values between 0 and 255.
    convenience init(integerRed red: Int, green: Int, blue: Int, alpha: CGFloat) {
        for c in [red, green, blue] {
            assert(0 <= c && c <= 255)
        }

        self.init(red: CGFloat(red) / 255,
                  green: CGFloat(green) / 255,
                  blue: CGFloat(blue) / 255,
                  alpha: alpha)
    }
}

extension UIActivityIndicatorView {

    /// Start optionally with delay and animation.
    /// Subsequent calls cancel previous delays that are underway.
    func start(after delay: TimeInterval? = nil, animated: Bool = true) {
        guard !isAnimating || isHidden else { return }

        NSObject.cancelPreviousPerformRequests(withTarget: self)

        let animated = animated as NSNumber

        if let delay = delay {
            perform(#selector(performStart), with: animated, afterDelay: delay)
        } else {
            performStart(animated: animated)
        }
    }

    func stop() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        isHidden = true
        stopAnimating()
    }

    @objc private func performStart(animated: NSNumber) {
        startAnimating()
        isHidden = false

        if animated.boolValue {
            animateIn()
        }
    }

    private func animateIn() {
        let duration = 0.1
        let scale: CGFloat = 1.2

        // Slight zoom in
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
            self.transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
        }, completion: { _ in
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
                self.transform = .identity
            })
        })
    }
}
