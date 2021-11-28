import CoreGraphics
import Foundation
import ImageIO

extension CGImage {

    /// Encodes the receiver with the given image encoding.
    ///
    /// Returns `nil` if creating the data fails for any reason, e.g. if the encoding is not
    /// supported on the device (such as HEIC on iPhone 6S and lower).
    func data(with encoding: ImageEncoding) -> Data? {
        let data = NSMutableData()

        let uti = encoding.format.uti as CFString
        var imageProperties = encoding.metadata?.properties ?? [:]
        
        if encoding.format.isLossyCompressionSupported {
            imageProperties[kCGImageDestinationLossyCompressionQuality] = encoding.compressionQuality
        }

        guard let destination = CGImageDestinationCreateWithData(data, uti, 1, nil) else { return nil }

        CGImageDestinationAddImage(destination, self, imageProperties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else { return nil }

        return data as Data
    }

    /// Encodes the receiver with the given image encoding and writes it to the given url.
    ///
    /// Returns `nil` if encoding or writing fails for any reason, e.g. if the encoding is not
    /// supported on the device (such as HEIC on iPhone 6S and lower).
    func write(to url: URL, with encoding: ImageEncoding) -> Bool {
        let uti = encoding.format.uti as CFString
        var imageProperties = encoding.metadata?.properties ?? [:]

        if encoding.format.isLossyCompressionSupported {
            imageProperties[kCGImageDestinationLossyCompressionQuality] = encoding.compressionQuality
        }

        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, uti, 1, nil) else { return false }

        CGImageDestinationAddImage(destination, self, imageProperties as CFDictionary)

        return CGImageDestinationFinalize(destination)
    }
}
