import CoreLocation
import Contacts
import UIKit

/// A formatter that formats locations by reverse geocoding them to addresses and caches
/// the result. The cache is auto-cleared on memory warning notifications.
class CachingGeocodingLocationFormatter {

    /// An instance that can be used for a shared location cache.
    static let shared = CachingGeocodingLocationFormatter()

    private lazy var geocoder = CLGeocoder()
    private lazy var addressFormatter = CNPostalAddressFormatter()
    private lazy var coordinateFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 5
        return formatter
    }()

    private lazy var cache = [CLLocation: CNPostalAddress]()

    init(center: NotificationCenter = .default) {
        center.addObserver(self, selector: #selector(clearCache), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }

    deinit {
        geocoder.cancelGeocode()
    }

    @objc func clearCache() {
        cache = [:]
    }

    /// If a geocode is in progress, it will be cancelled.
    /// The completion handler can be called twice if no address is immediately available,
    /// once with a formatted geocoordinate and once with the final address if successful.
    func string(from location: CLLocation, completion: @escaping (String?) -> ()) {
        if let cached = cache[location] {
            completion(string(from: cached))
            return
        }

        let formattedCoordinate = string(fromLatitudeLongitude: location.coordinate)
        completion(formattedCoordinate)

        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let address = placemarks?.first?.postalAddress else { return }
            self?.cache[location] = address
            completion(self?.string(from: address))
        }
    }

    /// Formats as a single line address.
    func string(from address: CNPostalAddress) -> String {
        addressFormatter.string(from: address).replacingOccurrences(of: "\n", with: ", ")
    }

    /// Formats as latitude and longitude decimal degree values.
    /// - Note: The string is not localized, it uses international format.
    func string(fromLatitudeLongitude coordinate: CLLocationCoordinate2D) -> String? {
        guard let lat = coordinateFormatter.string(from: coordinate.latitude as NSNumber),
            let long = coordinateFormatter.string(from: coordinate.longitude as NSNumber) else { return nil }

        let latRef = (coordinate.latitude >= 0) ? "N" : "S"
        let longRef = (coordinate.longitude >= 0) ? "E" : "W"

        return "\(lat)° \(latRef) \(long)° \(longRef)"
    }
}
