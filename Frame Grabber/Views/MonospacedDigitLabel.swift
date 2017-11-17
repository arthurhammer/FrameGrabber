import UIKit

/// A label using a monospaced system font for digits and a standard system font of the same size for non-digits.
class MonospacedDigitLabel: UILabel {

    var fontSize: CGFloat = 13 {
        didSet { update() }
    }

    var fontWeight = UIFont.Weight.regular {
        didSet { update() }
    }

    override var text: String? {
        didSet { update() }
    }

    override var attributedText: NSAttributedString? {
        didSet { update() }
    }

    /// Use `fontSize` and `fontWeight` in favor of `font`.
    override var font: UIFont! {
        didSet { update() }
    }

    private func update() {
        guard shouldUpdate,
            let attributedText = attributedText else { return }

        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        let font = UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
        
        // Base font for non-digits
        mutableText.addAttribute(.font, value: font, range: NSRange(location: 0, length: mutableText.length))

        // Monospaced font of same size for digits
        mutableText.addMonospacedDigitFontAttributes(ofSize: fontSize, weight: fontWeight)

        avoidingUpdate {
            self.attributedText = mutableText
        }
    }

    /// Update avoiding infinite loop when triggering setters
    private func avoidingUpdate(_ block: () -> ()) {
        shouldUpdate = false
        block()
        shouldUpdate = true
    }

    private var shouldUpdate = true
}
