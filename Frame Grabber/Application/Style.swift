import UIKit

struct Style {

    struct Color {
        static let mainTint = UIColor.systemBlue

        static var cellSelection: UIColor {
            .systemGray4
        }

        static var disabledLabel: UIColor {
            .systemGray
        }

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
        window?.tintColor = Style.Color.mainTint
        UINavigationBar.appearance().shadowImage = UIImage()
    }
}

extension UIView {
    func applyOverlayShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.8
        layer.shadowRadius = 2
        layer.shadowOffset = CGSize(width: 0, height: 1)
    }
}
