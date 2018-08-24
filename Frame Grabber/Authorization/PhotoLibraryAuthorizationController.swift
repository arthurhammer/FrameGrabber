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
        updateViews()
    }

    @IBAction private func requestAuthorization() {
        PHPhotoLibrary.requestAuthorization(openingSettingsIfNeeded: true) { status, _ in
            self.updateViews()

            if status == .authorized {
                self.didAuthorizeHandler?()
            }
        }
    }

    private func updateViews() {
        statusView.message = message(for: PHPhotoLibrary.authorizationStatus())
    }

    private func message(for status: PHAuthorizationStatus) -> StatusView.Message? {
        switch status {

        case .notDetermined:
            return .init(title: NSLocalizedString("Frame Grabber 👋", comment: ""),
                         message: NSLocalizedString("Frame Grabber lets you export video frames as images. Get started by allowing access to your Photo Library.", comment: ""),
                         action: NSLocalizedString("Allow Access", comment: ""))

        case .denied, .restricted:
            return .init(title: NSLocalizedString("Frame Grabber 👋", comment: ""),
                         message: NSLocalizedString("Frame Grabber lets you export video frames as images. You can allow access to your Photo Library in Settings.", comment: ""),
                         action: NSLocalizedString("Open Settings", comment: ""))

        case .authorized:
            return nil
        }
    }
}
