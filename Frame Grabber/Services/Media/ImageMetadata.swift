import CoreGraphics
import CoreLocation
import Foundation
import ImageIO

struct ImageMetadata {
    
    /// A dictionary of CGImageProperty metadata keys and their values.
    typealias Properties = [CFString: Any]

    /// The metadata properties.
    let properties: Properties
}

// MARK: - Factories

extension ImageMetadata {
    
    static func metadata(for creationDate: Date?, location: CLLocation?) -> ImageMetadata {
        var properties = Properties()

        if let date = creationDate {
            properties[kCGImagePropertyExifDictionary] = exifProperties(for: date)
            properties[kCGImagePropertyTIFFDictionary] = tiffProperties(for: date)
        }

        if let location = location {
            properties[kCGImagePropertyGPSDictionary] = gpsProperties(for: location)
        }

        return ImageMetadata(properties: properties)
    }

    static func exifProperties(for creationDate: Date) -> Properties {
        let exifDateString = DateFormatter.exifDateTimeFormatter().string(from: creationDate)
        return [kCGImagePropertyExifDateTimeOriginal: exifDateString as CFString]
    }

    static func tiffProperties(for creationDate: Date) -> Properties {
        let exifDateString = DateFormatter.exifDateTimeFormatter().string(from: creationDate)
        return [kCGImagePropertyTIFFDateTime: exifDateString as CFString]
    }

    static func gpsProperties(for location: CLLocation) -> Properties {
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

// MARK: - Formatters

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
