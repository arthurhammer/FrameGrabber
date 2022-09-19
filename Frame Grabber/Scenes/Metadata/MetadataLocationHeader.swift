import MapKit
import Utility
import UIKit

class MetadataLocationHeader: UITableViewHeaderFooterView {
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var openButton: UIButton!
    
    var mapPin: MKAnnotation? {
        didSet { showPin() }
    }

    /// Hides the header by constraining its height to 0, or shows it by disabling the constraint.
    func setHeaderHidden(_ hidden: Bool) {
        zeroHeightConstraint.isActive = hidden
        isHidden = hidden
    }
    
    private lazy var zeroHeightConstraint: NSLayoutConstraint = {
        heightAnchor.constraint(equalToConstant: 0)
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        DispatchQueue.main.async {
            self.showPin()  // Re-center.
        }
    }
    
    private func configureViews() {
        mapView.layer.cornerRadius = 12
        mapView.layer.cornerCurve = .continuous
        mapView.superview?.layer.cornerRadius = 12
        mapView.superview?.layer.cornerCurve = .continuous
        mapView.superview?.configureWithDefaultShadow()
        
        openButton.titleLabel?.font = .preferredFont(forTextStyle: .subheadline, weight: .semibold)
        openButton.configureDynamicTypeLabel()
    }
    
    private func showPin() {
        mapView.removeAnnotations(mapView.annotations)
        
        if let mapPin {
            let distance = 5000.0
            
            let region = MKCoordinateRegion(
                center: mapPin.coordinate,
                latitudinalMeters: distance,
                longitudinalMeters: distance
            )
            
            let zoomRange = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: distance)
            
            mapView.cameraBoundary = MKMapView.CameraBoundary(coordinateRegion: region)
            mapView.setCameraZoomRange(zoomRange, animated: false)
            mapView.showAnnotations([mapPin], animated: false)
        }
        
        mapView.layoutIfNeeded()
    }
}
