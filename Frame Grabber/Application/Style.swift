import UIKit

extension UIColor {
    static let accent = UIColor(named: "accent")
    static let secondaryAccent = UIColor(named: "secondaryAccent")
    static let iceCream = UIColor(named: "iceCream")
    static let cellSelection = UIColor(named: "cellSelection")
    static let videoCellGradient = [UIColor.black.withAlphaComponent(0), UIColor.black.withAlphaComponent(0.4)]

}

struct Style {

    static let buttonCornerRadius: CGFloat = 18
    static let staticTableViewTopMargin: CGFloat = 12

    static func configureAppearance() {
        UISwitch.appearance().onTintColor = .accent
    }
}

extension UIButton {

    func configureAsActionButton() {
        heightAnchor.constraint(equalToConstant: 50).isActive = true
        titleLabel?.font = .preferredFont(forTextStyle: .headline)
        configureDynamicTypeLabel()

        layer.cornerRadius = Style.buttonCornerRadius
        layer.cornerCurve = .continuous
    }

    func configureDynamicTypeLabel() {
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.allowsDefaultTighteningForTruncation = true
        titleLabel?.minimumScaleFactor = 0.6
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
