import UIKit

struct Style {

    struct Color {

        static let mainTint: UIColor = .init { traitCollection in
            (traitCollection.userInterfaceStyle == .light)
                ? UIColor(red: 0.27, green: 0.16, blue: 0.97, alpha: 1.00)
                : UIColor(red: 0.44, green: 0.36, blue: 0.95, alpha: 1.00) 
        }

        static let secondaryTint: UIColor = .init { traitCollection in
            (traitCollection.userInterfaceStyle == .light)
                ? UIColor(red: 0.23, green: 0.18, blue: 0.23, alpha: 1.00)
                : .white
        }

        static var cellSelection: UIColor = .systemGray4
        static var disabledLabel: UIColor = .systemGray
        static let videoCellGradient = [UIColor.black.withAlphaComponent(0), UIColor.black.withAlphaComponent(0.6)]
    }

    struct Size {
        static let buttonCornerRadius: CGFloat = 12
    }

    static func configureAppearance(using window: UIWindow?) {
        window?.tintColor = Style.Color.mainTint
        UISwitch.appearance().onTintColor = Style.Color.mainTint
    }
}

extension UIView {
    func applyOverlayShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.4
        layer.shadowRadius = 4
        layer.shadowOffset = .zero
    }
}
