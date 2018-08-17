import UIKit
import CoreLocation

// MARK: - Creating Images with Metadata

extension UIImage {

    /// Returns a jpg data representation of the receiver containing the given image
    /// metadata or `nil` if the creation fails.
    /// Metadata is merged into any existing metadata in the receiver.
    /// - Note: https://developer.apple.com/library/archive/qa/qa1895/_index.html
    func jpgImageData(withMetadata metadata: CGImageMetadata, quality: CGFloat) -> Data? {
        let imageOutputData = NSMutableData()

        guard
            let imageSourceData = UIImageJPEGRepresentation(self, quality),
            let imageSource = CGImageSourceCreateWithData(imageSourceData as CFData, nil),
            let uti = CGImageSourceGetType(imageSource),
            let imageDestination = CGImageDestinationCreateWithData(imageOutputData as CFMutableData, uti, 1, nil)
        else {
            return nil
        }

        let metadataOptions: [CFString: Any] = [
            kCGImageDestinationMetadata: metadata,
            kCGImageDestinationMergeMetadata: kCFBooleanTrue
        ]

        let ok = CGImageDestinationCopyImageSource(imageDestination, imageSource, metadataOptions as CFDictionary, nil)

        return ok ? (imageOutputData as Data) : nil
    }
}

// MARK: - Creating Metadata

extension CGImageMetadata {

    /// Metadata with Exif, TIFF and GPS tags for date and location.
    /// The returned success flag is `false` if at least one tag failed to be set.
    static func `for`(creationDate: Date?, location: CLLocation?) -> (ok: Bool, metadata: CGImageMetadata) {
        let metadata = CGImageMetadataCreateMutable()

        let ok = [
            creationDate.flatMap(metadata.setExifCreationDate),
            creationDate.flatMap(metadata.setTIFFCreationDate),
            location.flatMap(metadata.setGPSLocation)
        ]

        return (!ok.contains(false), metadata)
    }
}

// As an alternative to `CGImageMetadataSetValueMatchingImageProperty` see the more
// complex `CGImageMetadataSetTagWithPath` with `CGImageMetadataTagCreate`.

extension CGMutableImageMetadata {

    typealias Tag = (dictionary: CFString, property: CFString, value: CFTypeRef)

    @discardableResult
    func setTag(_ tag: Tag) -> Bool {
        return CGImageMetadataSetValueMatchingImageProperty(self, tag.dictionary, tag.property, tag.value)
    }

    @discardableResult
    func setTags(_ tags: [Tag]) -> Bool {
        return !tags.map(setTag).contains(false)
    }

    @discardableResult
    func setExifCreationDate(_ date: Date) -> Bool {
        let dateString = DateFormatter.exifDateTimeFormatter().string(from: date)
        return setTag((kCGImagePropertyExifDictionary, kCGImagePropertyExifDateTimeOriginal, dateString as CFString))
    }

    @discardableResult
    func setTIFFCreationDate(_ date: Date) -> Bool {
        let dateString = DateFormatter.exifDateTimeFormatter().string(from: date)
        return setTag((kCGImagePropertyTIFFDictionary, kCGImagePropertyTIFFDateTime, dateString as CFString))
    }

    /// Altitude, course and speed are currently not supported.
    @discardableResult
    func setGPSLocation(_ location: CLLocation) -> Bool {
        let dateString = DateFormatter.GPSTimeStampFormatter().string(from: location.timestamp)
        let coordinate = location.coordinate

        return setTags([
            (kCGImagePropertyGPSDictionary, kCGImagePropertyGPSTimeStamp, dateString as CFString),
            (kCGImagePropertyGPSDictionary, kCGImagePropertyGPSLatitude, "\(abs(coordinate.latitude))" as CFString),
            (kCGImagePropertyGPSDictionary, kCGImagePropertyGPSLatitudeRef, (coordinate.latitude >= 0 ? "N" : "S") as CFString),
            (kCGImagePropertyGPSDictionary, kCGImagePropertyGPSLongitude, "\(abs(coordinate.longitude))" as CFString),
            (kCGImagePropertyGPSDictionary, kCGImagePropertyGPSLongitudeRef, (coordinate.longitude >= 0 ? "E" : "N") as CFString),
            (kCGImagePropertyGPSDictionary, kCGImagePropertyGPSHPositioningError, "\(location.horizontalAccuracy)" as CFString)
        ])
    }
}

// MARK: - Util

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
