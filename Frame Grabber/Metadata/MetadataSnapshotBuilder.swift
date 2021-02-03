import AVFoundation
import Contacts
import CoreGraphics
import CoreLocation
import MapKit

/// Builds the location and snapshot data for `MetadataViewModel` from the set of video metadata.
struct MetadataSnapshotBuilder {
        
    var metadata = VideoSourceMetadata()
    var geocodedAddress: CNPostalAddress?
    
    init(video: AVAsset, source: VideoSource, videoMetadata: VideoMetadata? = nil) {
        let fileURL = (video as? AVURLAsset)?.url ?? source.url
        let fileMetadata = fileURL.flatMap(FileMetadata.init)
        let photoMetadata = source.asset.flatMap(PhotoLibraryMetadata.init)
                
        self.metadata = VideoSourceMetadata(
            video: videoMetadata,
            file: fileMetadata,
            photoLibrary: photoMetadata
        )
    }
    
    /// The table view data snapshot.
    func makeSnapshot() -> MetadataViewModel.DataSnapshot {
        var snapshot = MetadataViewModel.DataSnapshot()
        let items = makeItems()
        
        if !items.isEmpty {
            snapshot.appendSections([.main])
            snapshot.appendItems(items, toSection: .main)
        }

        return snapshot
    }
    
    /// The synthesized location info from the metadata location and the geocoded address.
    func makeLocation() -> MetadataViewModel.Location? {
        guard let location = metadataLocation else { return nil }
        
        let locationFormatter = LocationFormatter()

        let address = geocodedAddress.flatMap { locationFormatter.string(from: $0) }
            ?? locationFormatter.string(fromCoordinate: location.coordinate)
        
        let pin = MKPointAnnotation()
        pin.coordinate = location.coordinate

        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        mapItem.name = UserText.Metadata.mapItemTitle
        
        return MetadataViewModel.Location(mapPin: pin, mapItem: mapItem, address: address)
    }
    
    // MARK: - Building
    
    var metadataLocation: CLLocation? {
        // Photo library metadata is user-editable, prefer it over the actual video metadata.
        (metadata.photoLibrary?.location) ?? (metadata.video?.common?.location)
    }
    
    private var creationDate: Date? {
        (metadata.photoLibrary?.creationDate) ?? (metadata.video?.creationDate)
    }
    
    private var videoDimensions: CGSize? {
        (metadata.video?.track?.dimensions)
            ?? (isLivePhoto ? nil : (metadata.photoLibrary?.dimensions))
    }
    
    private var livePhotoPictureDimensions: CGSize? {
        isLivePhoto ? (metadata.photoLibrary?.dimensions) : nil
    }
    
    private  var duration: Double? {
        (metadata.video?.duration?.seconds)
            ?? (isLivePhoto ? nil : (metadata.photoLibrary?.duration))
    }

    private var type: String {
        isLivePhoto ? UserText.Metadata.typeLivePhotoValue : UserText.Metadata.typeVideoValue
    }

    private var isLivePhoto: Bool {
        metadata.photoLibrary?.subtypes.contains(.photoLive) == true
    }
    
    private var codec: String? {
        let codecs = metadata.video?.track?.formatDescriptions?.map {
            $0.mediaSubType.displayString
        }
            
        return codecs
            .flatMap { Array(Set($0)) }  // Can contain duplicates.
            .flatMap { $0.joined(separator: ", ") }
    }
    
    private func makeItems() -> [MetadataViewModel.Item] {
        let dateFormatter = DateFormatter.default()
        let dimensionsFormatter = NumberFormatter()
        let durationFormatter = VideoDurationFormatter()
        let frameRateFormatter = NumberFormatter.frameRateFormatter()
        let fileSizeFormatter = ByteCountFormatter()
        
        let date = creationDate.flatMap(dateFormatter.string)
        let videoDimensions = self.videoDimensions.flatMap(dimensionsFormatter.string)
        let pictureDimensions = livePhotoPictureDimensions.flatMap(dimensionsFormatter.string)
        let size = metadata.file?.size
        let frameRate = metadata.video?.track?.nominalFrameRate
        let formattedDuration = duration.flatMap(durationFormatter.string(from:))
        let formattedSize = size.flatMap(Int64.init).flatMap(fileSizeFormatter.string)
        let formattedFrameRate = frameRate.flatMap(frameRateFormatter.string(fromFrameRate:))

        return cruuuuuuuunch([
            (UserText.Metadata.typeTitle, type),
            (UserText.Metadata.creationDateTitle, date),
            (UserText.Metadata.dimensionsTitle, (isLivePhoto ? nil : videoDimensions)),
            (UserText.Metadata.dimensionsLivePhotoVideoTitle, (isLivePhoto ? videoDimensions : nil)),
            (UserText.Metadata.dimensionsLivePhotoPictureTitle, (isLivePhoto ? pictureDimensions : nil)),
            (UserText.Metadata.durationTitle, formattedDuration),
            (UserText.Metadata.frameRateTitle, formattedFrameRate),
            (UserText.Metadata.formatTitle, metadata.file?.formatDisplayString),
            (UserText.Metadata.codecTitle, codec),
            (UserText.Metadata.fileSizeTitle, formattedSize),
            (UserText.Metadata.cameraMakeTitle, metadata.video?.common?.make),
            (UserText.Metadata.cameraModelTitle, metadata.video?.common?.model),
            (UserText.Metadata.softwareTitle, metadata.video?.common?.software),
        ])
    }

    private typealias OptionalItem = (title: String, detail: String?)
    
    private func cruuuuuuuunch(_ items: [OptionalItem]) -> [MetadataViewModel.Item] {
        items.compactMap { item in
            (item.detail != nil)
                ? .init(title: item.title, detail: item.detail!)
                : nil
        }
    }
}
