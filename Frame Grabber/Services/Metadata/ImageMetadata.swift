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
    
    static func metadata(
        forCreationDate date: Date? = nil,
        location: CLLocation? = nil,
        make: String? = nil,
        model: String? = nil,
        software: String? = nil,
        userComment: String? = nil
    ) -> ImageMetadata {
        
        var properties = Properties()

        let exif = exifProperties(forCreationDate: date, userComment: userComment)
        let tiff = tiffProperties(forCreationDate: date, make: make, model: model, software: software)
                
        properties.setIfNotNil(kCGImagePropertyExifDictionary, exif.isEmpty ? nil : exif)
        properties.setIfNotNil(kCGImagePropertyTIFFDictionary, tiff.isEmpty ? nil : tiff)
        
        if let location {
            properties[kCGImagePropertyGPSDictionary] = gpsProperties(for: location)
        }

        return ImageMetadata(properties: properties)
    }

    static func exifProperties(
        forCreationDate date: Date? = nil,
        userComment: String? = nil
    ) -> Properties {
        
        var properties = Properties()
        let dateString = date.flatMap(ImageMetadataDateFormatter().exifTimestamp)

        properties.setIfNotNil(kCGImagePropertyExifDateTimeOriginal, dateString as CFString?)
        properties.setIfNotNil(kCGImagePropertyExifDateTimeDigitized, dateString as CFString?)
        properties.setIfNotNil(kCGImagePropertyExifUserComment, userComment as CFString?)
            
        return properties
    }

    static func tiffProperties(
        forCreationDate date: Date? = nil,
        make: String? = nil,
        model: String? = nil,
        software: String? = nil
    ) -> Properties {
        
        var properties = Properties()
        let dateString = date.flatMap(ImageMetadataDateFormatter().tiffTimestamp)
        
        properties.setIfNotNil(kCGImagePropertyTIFFDateTime, dateString as CFString?)
        properties.setIfNotNil(kCGImagePropertyTIFFMake, make as CFString?)
        properties.setIfNotNil(kCGImagePropertyTIFFModel, model as CFString?)
        properties.setIfNotNil(kCGImagePropertyTIFFSoftware, software as CFString?)
        
        return properties
    }

    static func gpsProperties(for location: CLLocation) -> Properties {
        let dateString = ImageMetadataDateFormatter().gpsTimestamp(from: location.timestamp)
        let coordinate = location.coordinate

        return [
            kCGImagePropertyGPSTimeStamp: dateString as CFString,
            kCGImagePropertyGPSLatitude: abs(coordinate.latitude),  // Note: not CFString
            kCGImagePropertyGPSLatitudeRef: (coordinate.latitude >= 0 ? "N" : "S") as CFString,
            kCGImagePropertyGPSLongitude: abs(coordinate.longitude),
            kCGImagePropertyGPSLongitudeRef: (coordinate.longitude >= 0 ? "E" : "W") as CFString,
            kCGImagePropertyGPSHPositioningError: location.horizontalAccuracy
        ]
    }
}

// MARK: - Util

private extension Dictionary {
    mutating func setIfNotNil(_ key: Key, _ value: Value?) {
        guard let value else { return }
        self[key] = value
    }
}
