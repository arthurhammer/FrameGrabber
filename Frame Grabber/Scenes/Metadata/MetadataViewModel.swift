import AVFoundation
import Combine
import MapKit

class MetadataViewModel {
    
    typealias DataSnapshot = NSDiffableDataSourceSnapshot<Section, Item>
    
    enum Section: Int, CaseIterable {
        case main
    }

    struct Item: Hashable {
        let title: String
        let detail: String
    }
    
    struct Location: Hashable {
        let mapPin: MKPointAnnotation
        let mapItem: MKMapItem?
        let address: String
    }

    @Published private(set) var snapshot: DataSnapshot
    @Published private(set) var location: Location?
    @Published private(set) var isLoading = true
    
    private let video: AVAsset
    private let geocoder: ReverseGeocoder
    
    private var builder: MetadataSnapshotBuilder {
        didSet {
            location = builder.makeLocation()
            let snapshot = builder.makeSnapshot()
            assert(snapshot.numberOfItems > 0, "Metadata empty. Might need an empty view indicator.")
            self.snapshot = snapshot
        }
    }
 
    init(
        video: AVAsset,
        source: VideoSource,
        geocoder: ReverseGeocoder = CachingGeocoder.shared
    ) {
        self.video = video
        self.geocoder = geocoder
        self.builder = MetadataSnapshotBuilder(video: video, source: source)
        
        self.location = builder.makeLocation()
        self.snapshot = builder.makeSnapshot()
        self.loadData()
    }
    
    private func loadData() {
        isLoading = true
        geocodeIfNeeded()
                
        video.loadMetadata { [weak self] metadata in
            DispatchQueue.main.async {
                self?.builder.metadata.video = metadata
                self?.geocodeIfNeeded()
                self?.isLoading = false
            }
        }
    }
    
    private func geocodeIfNeeded() {
        guard !geocoder.isGeocoding,
              builder.geocodedAddress == nil,
              let location = builder.metadataLocation else { return }

        geocoder.reverseGeocodeLocation(location) { [weak self] placemark in
            self?.builder.geocodedAddress = placemark?.postalAddress
        }
    }
}
