import UIKit

struct Style {

    struct Color {

        static let mainTint: UIColor = .init { traitCollection in
            (traitCollection.userInterfaceStyle == .light)
                ? UIColor(red: 0.27, green: 0.16, blue: 0.97, alpha: 1.00)
                : .systemTeal
        }

        static let secondaryTint: UIColor = .init { traitCollection in
            (traitCollection.userInterfaceStyle == .light)
                ? UIColor(red: 0.23, green: 0.18, blue: 0.23, alpha: 1.00)
                : .white
        }

        static let iceCream = UIColor(red: 0.97, green: 0.56, blue: 0.70, alpha: 1.00)

        static var cellSelection: UIColor = .secondarySystemFill
        static var disabledLabel: UIColor = .systemGray
        static let videoCellGradient = [UIColor.black.withAlphaComponent(0), UIColor.black.withAlphaComponent(0.6)]
    }

    struct Size {
        static let buttonCornerRadius: CGFloat = 18
    }

    static func configureAppearance(using window: UIWindow?) {
        window?.tintColor = Style.Color.mainTint
        UISwitch.appearance().onTintColor = Style.Color.mainTint
    }
}

extension UIView {
    func applyToolbarShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 10
        layer.shadowOffset = .zero
    }
}
