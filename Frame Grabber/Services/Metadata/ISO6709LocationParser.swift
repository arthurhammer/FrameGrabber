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
        let pattern = /(?<latitude>[+-][0-9.]+)(?<longitude>[+-][0-9.]+)(?<altitude>[+-][0-9.]+)?/
        let matches = string.matches(of: pattern)
        
        guard let groups = matches.first?.output,
              let latitude = Double(groups.latitude),
              let longitude = Double(groups.longitude)
        else {
            return nil
        }
                
        let altitudeString = groups.altitude
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
