import UIKit

extension UIColor {
    static let accent = UIColor(named: "accent")
    static let secondaryAccent = UIColor(named: "secondaryAccent")
    static let iceCream = UIColor(named: "iceCream")
    static let cellSelection = UIColor(named: "cellSelection")
    static let disabledLabel = UIColor(named: "disabledLabel")
    static let videoCellGradient = [UIColor.black.withAlphaComponent(0), UIColor.black.withAlphaComponent(0.4)]

}

struct Style {

    static let buttonCornerRadius: CGFloat = 18

    static func configureAppearance() {
        UISwitch.appearance().onTintColor = .accent
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
