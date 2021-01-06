import UIKit
import AVFoundation
import Photos
import MapKit

class MetadataViewController: UITableViewController {

    enum Section: Int, CaseIterable {
        case location
        case metadata
    }

    var videoController: VideoController? {
        didSet { updateAssetMetadata() }
    }

    private lazy var geocoder = CachingGeocoder.shared
    private lazy var locationFormatter = LocationFormatter()
    
    private let unavailablePlaceholder = "—"

    @IBOutlet private var assetTypeLabel: UILabel!
    @IBOutlet private var frameDimensionsTitleLabel: UILabel!
    @IBOutlet private var frameDimensionsLabel: UILabel!
    @IBOutlet private var livePhotoDimensionsLabel: UILabel!
    @IBOutlet private var frameRateLabel: UILabel!
    @IBOutlet private var durationLabel: UILabel!
    @IBOutlet private var dateCreatedLabel: UILabel!
    @IBOutlet private var locationCell: UITableViewCell!
    @IBOutlet private var locationLabel: UILabel!
    @IBOutlet private var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    @IBAction private func done() {
        dismiss(animated: true)
    }

    func openLocationInMaps() {
        guard let location = videoController?.asset.location else { return }
        let item = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        item.name = UserText.detailMapItem
        item.openInMaps(launchOptions: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let hasLocation = videoController?.asset.location != nil
        let hideRows = !hasLocation && (Section(section) == .location)
        
        return hideRows ? 0 : super.tableView(tableView, numberOfRowsInSection: section)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if Section(indexPath.section) == .location {
            openLocationInMaps()
        }
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let row = tableView.cellForRow(at: indexPath) else { return false }
        return row.accessoryType != .none
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let hasFirstSection = videoController?.asset.location != nil
        
        // Remove space if section hidden, otherwise default margin from the top
        if (section == 0) {
            return hasFirstSection ? Style.staticTableViewTopMargin : 0
        }
        
        // If first section is hidden, the second section becomes the first
        if (section == 1) {
            return hasFirstSection ? UITableView.automaticDimension : Style.staticTableViewTopMargin
        }
        
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        0
    }

    private func configureViews() {
        tableView.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
        tableView.backgroundColor = .clear
        
        mapView.isUserInteractionEnabled = false
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(done))

        updateAssetMetadata()
    }

    private func updateAssetMetadata() {
        guard isViewLoaded else { return }

        let frameRateFormatter = NumberFormatter.frameRateFormatter()
        let dimensionsFormatter = NumberFormatter()
        let dateFormatter = DateFormatter.default()
        let durationFormatter = VideoDurationFormatter()

        let asset = videoController?.asset
        let video = videoController?.video
        let isLivePhoto = asset?.isLivePhoto == true

        assetTypeLabel.text = isLivePhoto ? UserText.detailLivePhotoTitle : UserText.detailVideoTitle
        frameDimensionsTitleLabel.text = isLivePhoto ? UserText.detailFrameDimensionsForLivePhotoTitle : UserText.detailFrameDimensionsForVideoTitle
        livePhotoDimensionsLabel.superview?.isHidden = !isLivePhoto

        frameDimensionsLabel.text = video?.dimensions.flatMap(dimensionsFormatter.string(fromPixelDimensions:)) ?? unavailablePlaceholder
        livePhotoDimensionsLabel.text = (asset?.dimensions).flatMap(dimensionsFormatter.string(fromPixelDimensions:)) ?? unavailablePlaceholder
        frameRateLabel.text = video?.frameRate.flatMap(frameRateFormatter.string(fromFrameRate:)) ?? unavailablePlaceholder
        durationLabel.text = (video?.duration.seconds).flatMap(durationFormatter.string) ?? unavailablePlaceholder
        dateCreatedLabel.text = asset?.creationDate.flatMap(dateFormatter.string) ?? unavailablePlaceholder

        updateLocation()
    }

    private func updateLocation() {
        tableView.reloadData()  // Show/hide location cells.

        guard let location = videoController?.asset.location else {
            locationLabel.text = unavailablePlaceholder
            return
        }

        let point = MKPointAnnotation()
        point.coordinate = location.coordinate
        
        mapView.removeAnnotations(mapView.annotations)
        mapView.showAnnotations([point], animated: false)
        
        let text = locationFormatter.string(fromCoordinate: location.coordinate)
        updateLocationLabel(with: text)
                
        geocoder.reverseGeocodeLocation(location) { [weak self] address in
            guard let address = address?.postalAddress else { return }
            let text = self?.locationFormatter.string(from: address)
            self?.updateLocationLabel(with: text)
        }
    }
    
    private func updateLocationLabel(with text: String?) {
        locationLabel.text = text
        tableView.reloadData()
    }
}
