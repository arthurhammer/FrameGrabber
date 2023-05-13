import UIKit

extension UITraitCollection {
    
    /// Shorthand for `preferredContentSizeCategory.isAccessibilityCategory`.
    public var hasHugeContentSize: Bool {
        preferredContentSizeCategory.isAccessibilityCategory
    }

    /// True if the `preferredContentSizeCategory` properties are different.
    public func hasDifferentContentSize(comparedTo other: UITraitCollection?) -> Bool {
        (preferredContentSizeCategory != other?.preferredContentSizeCategory)
    }
}

extension UIContentSizeCategory {
    
    /// The default content size category: `.large`.
    public static var `default`: Self { .large }
}
