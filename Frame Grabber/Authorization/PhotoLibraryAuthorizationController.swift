import UIKit
import Photos

class PhotoLibraryAuthorizationController: UIViewController {

    static var needsAuthorization: Bool {
        return PHPhotoLibrary.authorizationStatus() != .authorized
    }

    var didAuthorizeHandler: (() -> ())?

    @IBOutlet private var statusView: StatusView!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        updateViews()
    }

    @objc func requestAuthorization() {
        PHPhotoLibrary.requestAuthorization(openingSettingsIfNeeded: true) { status, _ in
            self.updateViews()

            if status == .authorized {
                self.didAuthorizeHandler?()
            }
        }
    }
}

private extension PhotoLibraryAuthorizationController {

    func configureViews() {
        statusView.button.addTarget(self, action: #selector(requestAuthorization), for: .touchUpInside)
    }

    func updateViews() {
        let statusMessage = PHPhotoLibrary.authorizationStatus().statusMessage
        statusView.displayMessage(statusMessage)
    }
}

private extension PHAuthorizationStatus {

    var statusMessage: StatusViewMessage? {
        switch self {

        case .notDetermined:
            return StatusViewMessage(title: NSLocalizedString("Frame Grabber", comment: ""),
                                     message: NSLocalizedString("Export frames as images from your videos. Get started by allowing Frame Grabber access to your Photo Library.", comment: ""),
                                     action: NSLocalizedString("Allow Access", comment: ""))

        case .denied, .restricted:
            return StatusViewMessage(title: NSLocalizedString("Frame Grabber", comment: ""),
                                     message: NSLocalizedString("Export frames as images from your videos. Get started by allowing Frame Grabber access to your Photo Library.", comment: ""),
                                     action: NSLocalizedString("Open Settings", comment: ""))

        case .authorized:
            return nil
        }
    }
}
