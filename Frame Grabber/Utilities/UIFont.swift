import UIKit

extension UIFont {

    /// A monospaced digit font that scales for the given style.
    static func monospacedDigitSystemFont(forTextStyle style: TextStyle) -> UIFont {
        let baseDescriptor = preferredFont(forTextStyle: style).fontDescriptor
        let monoFont = monospacedDigitSystemFont(ofSize: baseDescriptor.pointSize, weight: .regular)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: monoFont)
    }

    /// The preferred scaled font for the given style adjusted with the given weight.
    static func preferredFont(forTextStyle style: TextStyle, weight: Weight) -> UIFont {
        let baseFont = preferredFont(forTextStyle: style)
        let baseSize = baseFont.fontDescriptor.pointSize
        return preferredFont(forTextStyle: style, size: baseSize, weight: weight)
    }

    /// A scaled font for the given base size adjusted for the weight and scaled for the style.
    static func preferredFont(forTextStyle style: TextStyle, size: CGFloat, weight: Weight) -> UIFont {
        let weightedFont = systemFont(ofSize: size, weight: weight)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: weightedFont)
    }
}
