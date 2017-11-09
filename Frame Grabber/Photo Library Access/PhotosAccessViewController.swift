import UIKit
import Photos

protocol PhotosAccessViewControllerDelegate: class {
    func didAuthorize()
}

class PhotosAccessViewController: UIViewController {

    weak var delegate: PhotosAccessViewControllerDelegate?
    @IBOutlet private var allowAccessButton: UIButton!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    deinit {
        print("deinit PhotosAccessViewController")
    }

    @IBAction func allowAccess() {
        // Go to settings if denied
        if isDeniedOrRestricted {
            openSettings()
            return
        }

        // Request athorization otherwise. If request denied, do nothing.
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.delegate?.didAuthorize()
                default:
                    self?.updateButton()
                }
            }
        }
    }
}

// MARK: - Private

private extension PhotosAccessViewController {

    func configureViews() {
        view.backgroundColor = .mainBackgroundColor

        allowAccessButton.titleLabel?.adjustsFontSizeToFitWidth = true
        allowAccessButton.titleLabel?.minimumScaleFactor = 0.5
        allowAccessButton.tintColor = .mainBackgroundColor
        allowAccessButton.layer.cornerRadius = 12
        allowAccessButton.layer.backgroundColor = UIColor.accentColor.cgColor

        updateButton()
    }

    var isDeniedOrRestricted: Bool {
        let status = PHPhotoLibrary.authorizationStatus()
        return status == .denied || status == .restricted
    }

    func updateButton() {
        let title = isDeniedOrRestricted ? NSLocalizedString("Open Settings", comment: "") : NSLocalizedString("Allow Access", comment: "")
        allowAccessButton.setTitle(title, for: .normal)
    }

    func openSettings() {
        guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString),
            UIApplication.shared.canOpenURL(settingsUrl) else { return }

        UIApplication.shared.open(settingsUrl)
    }
}
