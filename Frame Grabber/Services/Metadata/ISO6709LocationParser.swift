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
    func location(from string: String) -> CLLocation? {
        let components = components(from: string)
        
        guard let latitude = components?.latitude, let longitude = components?.longitude else {
            return nil
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        return CLLocation(
            coordinate: coordinate,
            altitude: components?.altitude ?? 0,
            horizontalAccuracy: -1,
            verticalAccuracy: -1,
            timestamp: Date()
        )
    }
    
    typealias LocationComponents = (latitude: Double, longitude: Double, altitude: Double?)
    
    private func components(from string: String) -> LocationComponents? {
        if #available(iOS 16.0, *) {
            return regexComponents(from: string)
        } else {
            return legacyComponents(from: string)
        }
    }
    
    @available(iOS 16.0, *)
    private func regexComponents(from string: String) -> LocationComponents? {
        let pattern = /(?<latitude>[+-][0-9.]+)(?<longitude>[+-][0-9.]+)(?<altitude>[+-][0-9.]+)?/
        let matches = string.matches(of: pattern)
        
        guard let groups = matches.first?.output,
              let latitude = Double(groups.latitude),
              let longitude = Double(groups.longitude)
        else {
            return nil
        }
        
        let altitude = groups.altitude.flatMap(Double.init)
        return (latitude, longitude, altitude)
    }
    
    @available(iOS, obsoleted: 16)
    private func legacyComponents(from string: String) -> LocationComponents? {
        let pattern = "([+-][0-9.]+)([+-][0-9.]+)([+-][0-9.]+)?"
        let groups = string.captureGroups(matching: pattern)
        
        guard let latitudeString = groups[safe: 1],
              let longitudeString = groups[safe: 2],
              let latitude = Double(latitudeString),
              let longitude = Double(longitudeString) else { return nil }
        
        let altitude = groups[safe: 3].flatMap(Double.init)
        return (latitude, longitude, altitude)
    }
}

// MARK: - Utilities

extension String {
    @available(iOS, obsoleted: 16)
    fileprivate func captureGroups(matching pattern: String) -> [String] {
        let fullRange = NSRange(location: 0, length: count)
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let result = regex.firstMatch(in: self, range: fullRange) else { return [] }
        
        return (0..<result.numberOfRanges)
            .map(result.range(at:))
            .compactMap { Range($0, in: self) }
            .map { String(self[$0]) }
    }
}

extension Collection {
    @available(iOS, obsoleted: 16)
    fileprivate subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
