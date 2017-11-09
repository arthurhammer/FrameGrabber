import UIKit

/// A label for mixed digits and non-digits with a monospaced font for the digits.
/// To set the base font for non-digits use the `font` property.
class MonospacedDigitLabel: UILabel {

    var digitFontSize: CGFloat = 13
    var digitFontWeight = UIFont.Weight.regular

    override var text: String? {
        didSet {
            guard let text = text else { return }
            let attributedText = NSMutableAttributedString(string: text)
            attributedText.addMonospacedDigitFontAttributes(ofSize: digitFontSize, weight: digitFontWeight)
            self.attributedText = attributedText
        }
    }
}
