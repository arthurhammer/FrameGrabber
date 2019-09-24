import UIKit
import CoreLocation

import AVFoundation

import AVFoundation
import UIKit
extension UIDevice {
    func isHEIFSupported() -> Bool {
        AVAssetExportSession.allExportPresets().contains(AVAssetExportPresetHEVCHighestQuality)
    }
}


// AVAssetExportSession.allExportPresets().contains(AVAssetExportPresetHEVCHighestQuality)

// - [ ] File HEVC as bug.
//    - Do NOT support it. Effore more trouble than worth and will be obsolete soon.
//    - wait for bug reports
//    - other apps don't handle it either, even good ones!

// - [ ] Fix settings localization
// - [ ] Change iCloud alert label to something more generic so HEVC can be included
// - [ ] Watch HEVC best practices WWDC videos
// - [ ] Implement HEVC saving based on device capabilities

// - [ ] ! Cells in settings consistent height

// DYNAMIC TYPE; context actions, ship features!

// DO NOT REFACTOR RIGHT NOW SHIP THIS FEATURE, refactor after. integrate into legacy code. straightforward

// jo just make gray in settings, dont hide (or?)

// Good idea?
struct MetadataImage {
    let image: UIImage
    let properties: ImageProperties
    let format: ImageFormat
}




extension CGImage {

    /// Returns a data representation of the receiver in the given format including the
    /// given image properties. Returns nil if creating the data fails, e.g. if the given
    /// format is not supported on the device (such as HEIC on iPhone 6S and lower).
    func data(with format: ImageFormat, properties: ImageProperties?, compressionQuality: Double) -> Data? {
        var properties = properties ?? ImageProperties()
        properties[kCGImageDestinationLossyCompressionQuality] = compressionQuality
        let data = NSMutableData()
        print(properties)

        guard let destination = CGImageDestinationCreateWithData(data, format.rawValue as CFString, 1, nil) else { return nil }

        CGImageDestinationAddImage(destination, self, properties as CFDictionary)
        let ok = CGImageDestinationFinalize(destination)

        return ok ? (data as Data) : nil
    }
}

// MARK: - Creating Metadata

typealias ImageProperties = [CFString: Any]

extension CGImage {

    static func properties(for creationDate: Date?, location: CLLocation?) -> ImageProperties {
        var properties = ImageProperties()

        if let date = creationDate {
            properties[kCGImagePropertyExifDictionary] = exifDictionary(for: date)
            properties[kCGImagePropertyTIFFDictionary] = tiffDictionary(for: date)
        }

        if let location = location {
            properties[kCGImagePropertyGPSDictionary] = gpsDictionary(for: location)
        }

        return properties
    }

    static func exifDictionary(for creationDate: Date) -> ImageProperties {
        let exifDateString = DateFormatter.exifDateTimeFormatter().string(from: creationDate)
        return [kCGImagePropertyExifDateTimeOriginal: exifDateString as CFString]
    }

    static func tiffDictionary(for creationDate: Date) -> ImageProperties {
        let exifDateString = DateFormatter.exifDateTimeFormatter().string(from: creationDate)
        return [kCGImagePropertyTIFFDateTime: exifDateString as CFString]
    }

    static func gpsDictionary(for location: CLLocation) -> ImageProperties {
        let gpsDateString = DateFormatter.GPSTimeStampFormatter().string(from: location.timestamp)
        let coordinate = location.coordinate

        return [
            kCGImagePropertyGPSTimeStamp: gpsDateString as CFString,
            kCGImagePropertyGPSLatitude: abs(coordinate.latitude),  // Note: not CFString
            kCGImagePropertyGPSLatitudeRef: (coordinate.latitude >= 0 ? "N" : "S") as CFString,
            kCGImagePropertyGPSLongitude: abs(coordinate.longitude),
            kCGImagePropertyGPSLongitudeRef: (coordinate.longitude >= 0 ? "E" : "W") as CFString,
            kCGImagePropertyGPSHPositioningError: location.horizontalAccuracy
        ]
    }
}

private extension DateFormatter {

    static func exifDateTimeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        // Exif dates are in "local" time without any timezone (whatever that means…).
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter
    }

    static func GPSTimeStampFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter
    }
}
