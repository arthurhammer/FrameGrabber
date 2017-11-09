// MARK: - Foundation

import Foundation

extension IndexSet {
    /// An array of `IndexPath`s from an `IndexSet`. Sections set to 0.
    var indexPaths: [IndexPath] {
        return map { IndexPath(item: $0, section: 0) }
    }
}

extension Sequence where Element == IndexPath {
    /// An `IndexSet` from a sequence of `IndexPath`s. Ignoring sections.
    var indexSet: IndexSet {
        return IndexSet(map { $0.item })
    }
}

// MARK: Monospaced Digit Strings

extension NSMutableAttributedString {
    /// Adds a monospaced system font of the given size and weight to all digits in the receiver.
    /// Non-digit characters are unaffected.
    func addMonospacedDigitFontAttributes(ofSize size: CGFloat, weight: UIFont.Weight) {
        let font = UIFont.monospacedDigitSystemFont(ofSize: size, weight: weight)

        (mutableString as String).digitRanges().forEach {
            addAttribute(.font, value: font, range: $0)
        }
    }
}

extension String {

    /// An array of ranges of consecutive digits in the receiver.
    func digitRanges() -> [NSRange] {
        let testString = self + "."  // Terminate last possible range
        var ranges = [NSRange]()
        var startLocation = 0
        var length = 0

        testString.enumerated().forEach { idx, character in
            if character.isDigit {
                length += 1
            } else {
                // Found completed range of digits
                if length > 0 {
                    let range = NSRange(location: startLocation, length: length)
                    ranges.append(range)
                }

                // Restart with next character
                startLocation = idx + 1
                length = 0
            }
        }

        return ranges
    }
}

extension Character {
    /// `true` if this character is a digit.
    var isDigit: Bool {
        let hasNonDigits = unicodeScalars.contains { !$0.isDigit }
        return !hasNonDigits
    }
}

extension UnicodeScalar {
    /// `true` if this scalar is a digit.
    var isDigit: Bool {
        return CharacterSet.decimalDigits.contains(self)
    }
}

// MARK: - UIKit

import UIKit

extension UIColor {
    /// A color from RGB integer values between 0 and 255.
    convenience init(integerRed red: Int, green: Int, blue: Int, alpha: CGFloat) {
        for c in [red, green, blue] {
            assert(0 <= c && c <= 255)
        }

        self.init(red: CGFloat(red) / 255,
                  green: CGFloat(green) / 255,
                  blue: CGFloat(blue) / 255,
                  alpha: alpha)
    }
}

extension UIActivityIndicatorView {

    func startAndShow() {
        isHidden = false
        startAnimating()
    }

    func stopAndHide() {
        stopAnimating()
        isHidden = true
    }
}

// MARK: - AVKit

import AVKit

extension AVAssetImageGenerator {

    /// ...
    func copyCGImage(atExactTime time: CMTime, handler: (Error?, CGImage?) -> ()) {
        let oldToleranceBefore = requestedTimeToleranceBefore
        let oldToleranceAfter = requestedTimeToleranceAfter

        defer {
            requestedTimeToleranceBefore = oldToleranceBefore
            requestedTimeToleranceAfter = oldToleranceAfter
        }

        requestedTimeToleranceBefore = kCMTimeZero
        requestedTimeToleranceAfter = kCMTimeZero

        let image: CGImage?

        do {
            image = try copyCGImage(at: time, actualTime: nil)
        } catch let error {
            handler(error, nil)
            return
        }

        handler(nil, image)
    }
}
