import UIKit
import AVFoundation
import Photos
import MapKit

class MetadataViewController: UITableViewController {

    enum Section: Int, CaseIterable {
        case metadata
        case location
    }

    var videoController: VideoController? {
        didSet { updateAssetMetadata() }
    }

    var settings = UserDefaults.standard

    private lazy var locationFormatter = CachingGeocodingLocationFormatter.shared
    private let notAvailablePlaceholder = "—"

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

    override func numberOfSections(in tableView: UITableView) -> Int {
        let sections = Section.allCases.count
        let hasLocation = videoController?.asset.location != nil
        return hasLocation ? sections : (sections-1)
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
        (section == 0) ? Style.staticTableViewTopMargin : UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        0
    }

    private func configureViews() {
        tableView.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
        tableView.backgroundColor = .clear

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

        frameDimensionsLabel.text = video?.dimensions.flatMap(dimensionsFormatter.string(fromPixelDimensions:)) ?? notAvailablePlaceholder
        livePhotoDimensionsLabel.text = (asset?.dimensions).flatMap(dimensionsFormatter.string(fromPixelDimensions:)) ?? notAvailablePlaceholder
        frameRateLabel.text = video?.frameRate.flatMap(frameRateFormatter.string(fromFrameRate:)) ?? notAvailablePlaceholder
        durationLabel.text = (video?.duration.seconds).flatMap(durationFormatter.string) ?? notAvailablePlaceholder
        dateCreatedLabel.text = asset?.creationDate.flatMap(dateFormatter.string) ?? notAvailablePlaceholder

        updateLocation()
    }

    private func updateLocation() {
        tableView.reloadData()  // Show/hide location cells.
        mapView.isUserInteractionEnabled = false

        guard let location = videoController?.asset.location else {
            locationLabel.text = notAvailablePlaceholder
            return
        }

        let point = MKPointAnnotation()
        point.coordinate = location.coordinate
        mapView.addAnnotation(point)

        mapView.removeAnnotations(mapView.annotations)
        mapView.showAnnotations([point], animated: false)

        locationFormatter.string(from: location) { [weak self] string in
            guard let string = string else { return }
            self?.locationLabel.text = string
            self?.tableView.reloadData()  // Update cell height for new text.
        }
    }
}
