import ImageIO
import CoreLocation

extension CGImage {

    typealias Metadata = [CFString: Any]

    /// Returns a data representation of the receiver in the given format including the
    /// given image properties. Returns nil if creating the data fails, e.g. if the given
    /// format is not supported on the device (such as HEIC on iPhone 6S and lower).
    func data(with encoding: ImageEncoding) -> Data? {
        let data = NSMutableData()

        let uti = encoding.format.uti as CFString
        var properties = encoding.metadata ?? Metadata()
        properties[kCGImageDestinationLossyCompressionQuality] = encoding.compressionQuality

        guard let destination = CGImageDestinationCreateWithData(data, uti, 1, nil) else { return nil }

        CGImageDestinationAddImage(destination, self, properties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else { return nil }

        return data as Data
    }

    func write(to url: URL, with encoding: ImageEncoding) -> Bool {
        let uti = encoding.format.uti as CFString
        var properties = encoding.metadata ?? Metadata()
        properties[kCGImageDestinationLossyCompressionQuality] = encoding.compressionQuality

        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, uti, 1, nil) else { return false }

        CGImageDestinationAddImage(destination, self, properties as CFDictionary)

        return CGImageDestinationFinalize(destination)
    }
}

// MARK: - Creating Metadata

extension CGImage {

    static func metadata(for creationDate: Date?, location: CLLocation?) -> Metadata {
        var properties = Metadata()

        if let date = creationDate {
            properties[kCGImagePropertyExifDictionary] = exifDictionary(for: date)
            properties[kCGImagePropertyTIFFDictionary] = tiffDictionary(for: date)
        }

        if let location = location {
            properties[kCGImagePropertyGPSDictionary] = gpsDictionary(for: location)
        }

        return properties
    }

    static func exifDictionary(for creationDate: Date) -> Metadata {
        let exifDateString = DateFormatter.exifDateTimeFormatter().string(from: creationDate)
        return [kCGImagePropertyExifDateTimeOriginal: exifDateString as CFString]
    }

    static func tiffDictionary(for creationDate: Date) -> Metadata {
        let exifDateString = DateFormatter.exifDateTimeFormatter().string(from: creationDate)
        return [kCGImagePropertyTIFFDateTime: exifDateString as CFString]
    }

    static func gpsDictionary(for location: CLLocation) -> Metadata {
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
