import UIKit

extension CGSize {
    // The receiver scaled with the screen's scale.
    var scaledToScreen: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: width * scale, height: height * scale)
    }
}

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

    /// The receiver rendered as an image.
    func snapshotImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        // Alternative `drawHierarchy` wouldn't work in some cases
        layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    // MARK: Blur

    /// True if there is a `UIVisualEffectView` subview with blur effect.
    var isBlurred: Bool {
        for case let view as UIVisualEffectView in subviews where view.effect is UIBlurEffect {
            return true
        }
        return false
    }

    /// Adds a `UIVisualEffectView` with a blur effect as the first subview.
    /// The background color is set to `nil`.
    func blur(with style: UIBlurEffectStyle) {
        guard !isBlurred else { return }

        let effect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: effect)
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.isUserInteractionEnabled = false
        insertSubview(blurView, at: 0)
        backgroundColor = nil
    }

    /// Removes any `UIVisualEffectView` subview with blur effect.
    /// The view's background color is unaffected.
    func removeBlur() {
        for case let view as UIVisualEffectView in subviews where view.effect is UIBlurEffect {
            view.removeFromSuperview()
        }
    }

    // MARK: Animations

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

    func bump(by scale: CGFloat, withDuration duration: TimeInterval = 0.15, completion: ((Bool) -> ())? = nil) {
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
            self.transform = self.transform.scaledBy(x: scale, y: scale)
        }, completion: { _ in
            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
                self.transform = .identity
            }, completion: completion)
        })
    }
}

extension UICollectionView {
    func clearSelection() {
        selectItem(at: nil, animated: true, scrollPosition: .top)
    }
}

extension UIActivityIndicatorView {

    /// Start and show, optionally with delay and animation.
    /// Subsequent calls cancel previous in-flight delays and start a new delay.
    func start(after delay: TimeInterval? = nil, animated: Bool = false) {
        guard !isAnimating || isHidden else { return }

        NSObject.cancelPreviousPerformRequests(withTarget: self)

        let animated = animated as NSNumber

        if let delay = delay {
            perform(#selector(performStart), with: animated, afterDelay: delay)
        } else {
            performStart(animated: animated)
        }
    }

    /// Stop and hide
    func stop() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        isHidden = true
        stopAnimating()
    }

    @objc private func performStart(animated: NSNumber) {
        startAnimating()
        isHidden = false

        if animated.boolValue {
            bump(by: 1.2)
        }
    }
}

extension UISlider {

    /// Sets an image with the given attributes as thumb image.
    func setThumbSize(_ size: CGSize, cornerRadius: CGFloat, color: UIColor, for state: UIControlState) {
        setThumbImage(image(withSize: size, cornerRadius: cornerRadius, color: color), for: state)
    }

    /// Sets an image with the given attributes as track image.
    func setMinimumTrackHeight(_ height: CGFloat, cornerRadius: CGFloat, color: UIColor, for state: UIControlState) {
        setMinimumTrackImage(resizableImage(withHeight: height, cornerRadius: cornerRadius, color: color), for: state)
    }

    /// Sets an image with the given attributes as track image.
    func setMaximumTrackHeight(_ height: CGFloat, cornerRadius: CGFloat, color: UIColor, for state: UIControlState) {
        setMaximumTrackImage(resizableImage(withHeight: height, cornerRadius: cornerRadius, color: color), for: state)
    }

    private func image(withSize size: CGSize, cornerRadius: CGFloat, color: UIColor) -> UIImage? {
        return view(withSize: size, cornerRadius: cornerRadius, backgroundColor: color).snapshotImage()
    }

    private func resizableImage(withHeight height: CGFloat, cornerRadius: CGFloat, color: UIColor) -> UIImage? {
        // Track image is resizable in width:
        // Left and right non-stretchable rounded corners and 1 pt stretchable middle
        let size = CGSize(width: 2 * cornerRadius + 1, height: height)
        let insets = UIEdgeInsets(top: 0, left: cornerRadius, bottom: 0, right: cornerRadius)

        return view(withSize: size, cornerRadius: cornerRadius, backgroundColor: color)
            .snapshotImage()?
            .resizableImage(withCapInsets: insets)
    }

    private func view(withSize size: CGSize, cornerRadius: CGFloat, backgroundColor: UIColor) -> UIView {
        let view = UIView()
        view.bounds.size = size
        view.backgroundColor = backgroundColor
        view.layer.cornerRadius = cornerRadius
        view.isOpaque = false
        return view
    }
}
