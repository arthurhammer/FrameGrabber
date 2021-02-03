import UIKit

extension UITraitCollection {
    
    /// Shorthand for `preferredContentSizeCategory.isAccessibilityCategory`.
    var hasHugeContentSize: Bool {
        preferredContentSizeCategory.isAccessibilityCategory
    }

    /// True if the `preferredContentSizeCategory` properties are different.
    func hasDifferentContentSize(comparedTo other: UITraitCollection?) -> Bool {
        (preferredContentSizeCategory != other?.preferredContentSizeCategory)
    }
}
