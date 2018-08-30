import UIKit

struct Style {

    struct Color {
        static let mainTint = UIColor(red: 0, green:122/255, blue:1, alpha:1.00)
        static let missingThumbnail = UIColor(white: 0.95, alpha: 1)

        static let timeSlider = UIColor(white: 0.65, alpha: 1)
        static let disabledTimeSlider = Style.Color.timeSlider.withAlphaComponent(0.4)

        static let videoCellGradient = [UIColor.black.withAlphaComponent(0), UIColor.black.withAlphaComponent(0.6)]
        static let overlayTopGradient = [UIColor.black.withAlphaComponent(0.4), UIColor.black.withAlphaComponent(0)]
        static let overlayBottomGradient = [UIColor.black.withAlphaComponent(0), UIColor.black.withAlphaComponent(0.4)]
    }

    struct Size {
        static let buttonCornerRadius: CGFloat = 8
    }

    static func configureAppearance(using window: UIWindow?) {
        // `UIView.appearance().tintColor` makes it hard to overwrite colors later.
        window?.tintColor = Style.Color.mainTint
        UINavigationBar.appearance().barTintColor = .white
        UINavigationBar.appearance().shadowImage = UIImage()
    }
}

extension UIColor {
    static let mainTint = Style.Color.mainTint
}

extension UIView {
    func applyOverlayShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.8
        layer.shadowRadius = 2
        layer.shadowOffset = CGSize(width: 0, height: 1)
    }
}
