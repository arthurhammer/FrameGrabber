import CoreLocation
import Contacts
import UIKit

protocol ReverseGeocoder {
    func reverseGeocodeLocation(_ location: CLLocation, completion: @escaping (CLPlacemark?) -> ())
    func cancelGeocode()
    var isGeocoding: Bool { get }
}

/// Reverse geocodes locations and caches the results.
///
/// The cache is cleared on low memory warnings.
class CachingGeocoder: ReverseGeocoder {
    
    /// An instance that can be used for a shared location cache.
    static let shared = CachingGeocoder()
    
    var isGeocoding: Bool {
        geocoder.isGeocoding
    }
    
    private lazy var geocoder = CLGeocoder()
    private lazy var cache = [CLLocation: CLPlacemark]()
    
    init(center: NotificationCenter = .default) {
        observeMemoryWarnings(using: center)
    }

    deinit {
        cancelGeocode()
    }
    
    @objc func clearCache() {
        cache = [:]
    }
    
    func cancelGeocode() {
        geocoder.cancelGeocode()
    }
    
    /// If a geocode is in progress, it will be cancelled.
    ///
    /// If the location is cached, the handler is called synchronously on the current queue.
    /// Otherwise, it is called asynchronously on the main queue.
    func reverseGeocodeLocation(_ location: CLLocation, completion: @escaping (CLPlacemark?) -> ()) {
        if let cached = cache[location] {
            completion(cached)
            return
        }

        cancelGeocode()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let address = placemarks?.first else { return }
            self?.cache[location] = address
            completion(address)
        }
    }
    
    private func observeMemoryWarnings(using center: NotificationCenter) {
        center.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
}
