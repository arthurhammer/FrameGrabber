// MARK: - CoreGraphics

import CoreGraphics
import UIKit.UIScreen

extension CGSize {
    // This size scaled to the screen's size.
    var scaledToScreen: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: width * scale, height: height * scale)
    }
}

// MARK: - Foundation

import Foundation

extension NSObject {
    static var className: String {
        return String(describing: self)
    }
}

extension IndexSet {
    /// An array of `IndexPath`s from an `IndexSet` with sections set to 0.
    var indexPaths: [IndexPath] {
        return map { IndexPath(item: $0, section: 0) }
    }
}

extension Sequence where Element == IndexPath {
    /// An `IndexSet` from a sequence of `IndexPath`s ignoring sections.
    var indexSet: IndexSet {
        return IndexSet(map { $0.item })
    }
}

// MARK: Monospaced Digit Strings

extension NSMutableAttributedString {

    /// Adds a monospaced system font of the given size and weight to all digits in the receiver.
    /// Non-digits are unaffected.
    func addMonospacedDigitFontAttributes(ofSize size: CGFloat, weight: UIFont.Weight) {
        let font = UIFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
        addAttribute(.font, value: font, ranges: string.digitRanges())
    }

    func addAttribute(_ name: NSAttributedStringKey, value: Any, ranges: [NSRange]) {
        ranges.forEach {
            addAttribute(.font, value: value, range: $0)
        }
    }
}

extension NSString {

    /// An array of ranges for all digits in the receiver.
    func digitRanges() -> [NSRange] {

        // Note: There's some funky stuff between NSAttributedString, NSString, String, Range and NSRange.
        //       Converting between NSString and String results in mismatched ranges for unicode characters.
        //       The following works with NSAttributedString, NSString, NSRange with unicode and localization.

        let digits = CharacterSet.decimalDigits
        var ranges = [NSRange]()

        (0..<length).forEach {
            // Searching one character at a time...
            let searchRange = NSRange(location: $0, length: 1)
            let foundRange = rangeOfCharacter(from: digits, options: [], range: searchRange)

            if foundRange.location != NSNotFound {
                ranges.append(foundRange)
            }
        }

        return ranges
    }
}
