import UIKit

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
}

private extension UISlider {

    func image(withSize size: CGSize, cornerRadius: CGFloat, color: UIColor) -> UIImage? {
        return UIView(size: size, cornerRadius: cornerRadius, backgroundColor: color).snapshotImage()
    }

    func resizableImage(withHeight height: CGFloat, cornerRadius: CGFloat, color: UIColor) -> UIImage? {
        // Track image is resizable in width:
        // Left and right non-stretchable rounded corners and 1 point stretchable middle
        let size = CGSize(width: 2 * cornerRadius + 1, height: height)
        let insets = UIEdgeInsets(top: 0, left: cornerRadius, bottom: 0, right: cornerRadius)

        return image(withSize: size, cornerRadius: cornerRadius, color: color)?
            .resizableImage(withCapInsets: insets)
    }
}

private extension UIView {

    convenience init(size: CGSize, cornerRadius: CGFloat, backgroundColor: UIColor) {
        self.init(frame: CGRect(origin: .zero, size: size))
        self.backgroundColor = backgroundColor
        self.layer.cornerRadius = cornerRadius
        self.isOpaque = false
    }

    func snapshotImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        // `drawHierarchy` as an alternative wouldn't work in some cases
        layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}
