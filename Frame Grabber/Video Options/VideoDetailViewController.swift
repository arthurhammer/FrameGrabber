import UIKit
import AVFoundation
import Photos
import MapKit

class VideoDetailViewController: UITableViewController {

    enum Section: Int, CaseIterable {
        case options
        case video
        case location
    }

    var videoController: VideoController? {
        didSet { updateViews() }
    }

    var settings = UserDefaults.standard

    @IBOutlet private var metadataSwitch: UISwitch!
    @IBOutlet private var imageFormatLabel: UILabel!

    @IBOutlet private var dimensionsLabel: UILabel!
    @IBOutlet private var frameRateLabel: UILabel!
    @IBOutlet private var dateCreatedLabel: UILabel!
    @IBOutlet private var locationLabel: UILabel!
    @IBOutlet private var mapView: MKMapView!

    @IBOutlet private var locationCell: UITableViewCell!

    private lazy var locationFormatter = CachingGeocodingLocationFormatter.shared
    private let notAvailablePlaceholder = "—"

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateFrameSettings()
    }

    @IBAction private func done() {
        dismiss(animated: true)
    }

    @IBAction private func metadataOptionDidChange(_ sender: UISwitch) {
        settings.includeMetadata = sender.isOn
    }

    func openLocationInMaps() {
        guard let location = videoController?.location else { return }
        let item = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        item.name = NSLocalizedString("more.mapTitle", value: "Your Video", comment: "Title of map item opened in Maps app.")
        item.openInMaps(launchOptions: nil)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        let sections = Section.allCases.count
        return (videoController?.location == nil) ? (sections-1) : sections
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard Section(indexPath.section) == .location else { return }
        openLocationInMaps()
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        (Section(section) == .video) ? 0 : UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = Section(section)?.title else { return nil }
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: VideoDetailSectionHeader.name) as? VideoDetailSectionHeader else { fatalError("Wrong view id or type.") }
        view.titleLabel.text = title
        return view
    }

    private func configureViews() {
        tableView.register(VideoDetailSectionHeader.nib, forHeaderFooterViewReuseIdentifier: VideoDetailSectionHeader.name)

        if #available(iOS 13, *) {
            tableView.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
            tableView.backgroundColor = .clear
        }

        updateViews()
    }

    private func updateViews() {
        guard isViewLoaded else { return }
        updateFrameSettings()
        updateAssetMetadata()
     }


    private func updateFrameSettings() {
        metadataSwitch.isOn = settings.includeMetadata

        if let quality = NumberFormatter.percentFormatter().string(from: settings.compressionQuality as NSNumber) {
            imageFormatLabel.text = "\(settings.imageFormat.displayString) \(quality)"
        } else {
            imageFormatLabel.text = settings.imageFormat.displayString
        }
    }

    private func updateAssetMetadata() {
        let frameRateFormatter = NumberFormatter.frameRateFormatter()
        let dimensionsFormatter = NumberFormatter()
        let dateFormatter = DateFormatter.default()

        frameRateLabel.text = videoController?.frameRate.flatMap(frameRateFormatter.string(fromFrameRate:)) ?? notAvailablePlaceholder
        dimensionsLabel.text = (videoController?.dimensions).flatMap(dimensionsFormatter.string(fromPixelDimensions:)) ?? notAvailablePlaceholder
        dateCreatedLabel.text = videoController?.creationDate.flatMap(dateFormatter.string) ?? notAvailablePlaceholder

        updateLocation()
    }

    private func updateLocation() {
        // (Don't call `reloadData` in `viewWillAppear` since that can be called multiple
        // times during the sheet interactive dismissal and leads to glitches.)
        tableView.reloadData()  // Show/hide location cells.
        mapView.isUserInteractionEnabled = false

        guard let location = videoController?.location else {
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

    @objc private func handleMapTap(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else { return }
        openLocationInMaps()
    }
}

extension VideoDetailViewController.Section {
    var title: String? {
        switch self {
        case .options: return NSLocalizedString("more.section.options", value: "Frame Options", comment: "Video detail frame export settings section header")
        case .video: return NSLocalizedString("more.section.video", value: "Video", comment: "Video detail video metadata section header")
        case .location: return nil
        }
    }
}
