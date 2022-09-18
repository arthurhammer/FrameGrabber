import CoreLocation
import Foundation

struct ISO6709LocationParser {
    
    /// Parses a subset of ISO 6709 locations, as used by the Apple QuickTime video format.
    ///
    /// Only decimal degress are supported. The coordinate reference system (CRS) component is not
    /// supported, coordinates are always interpreted according to the WGS 84 reference frame.
    ///
    /// A typical string might look like: `+23.0384+016.3672+42.078/`.
    ///
    /// The timestamp of the location contains the current date.
    ///
    /// - SeeAlso: https://en.wikipedia.org/wiki/ISO_6709
    func location(from sring: String) -> CLLocation? {
        let pattern = "([+-][0-9.]+)([+-][0-9.]+)([+-][0-9.]+)?"
        let groups = sring.captureGroups(matching: pattern)
        
        guard let latitudeString = groups[safe: 1],
              let longitudeString = groups[safe: 2],
              let latitude = Double(latitudeString),
              let longitude = Double(longitudeString) else { return nil }
        
        let altitudeString = groups[safe: 3]
        let altitude = altitudeString.flatMap(Double.init)
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        return CLLocation(
            coordinate: coordinate,
            altitude: altitude ?? 0,
            horizontalAccuracy: -1,
            verticalAccuracy: -1,
            timestamp: Date()
        )
    }
}

// MARK: - Utilities

private extension String {
    
    func captureGroups(matching pattern: String) -> [String] {
        let fullRange = NSRange(location: 0, length: count)
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let result = regex.firstMatch(in: self, range: fullRange) else { return [] }
        
        return (0..<result.numberOfRanges)
            .map(result.range(at:))
            .compactMap { Range($0, in: self) }
            .map { String(self[$0]) }
    }
}

private extension Collection {
    
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
