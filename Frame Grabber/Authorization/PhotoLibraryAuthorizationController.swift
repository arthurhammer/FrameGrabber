import UIKit
import Photos
import SafariServices

class PhotoLibraryAuthorizationController: UIViewController {

    static var needsAuthorization: Bool {
        PHPhotoLibrary.authorizationStatus() != .authorized
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

    @IBAction private func showPrivacyPolicy() {
        guard let url = AboutViewController.privacyPolicyURL else { return }
        present(SFSafariViewController(url: url), animated: true)
    }

    private func updateViews() {
        statusView.message = message(for: PHPhotoLibrary.authorizationStatus())
    }

    private func message(for status: PHAuthorizationStatus) -> StatusView.Message? {
        let title = NSLocalizedString("authorization.title", value: "Frame Grabber 👋", comment: "Photo library authorization title")

        switch status {

        case .denied, .restricted:
            return .init(title: title,
                         message: NSLocalizedString("authorization.deniedMessage", value: "Frame Grabber exports video frames as images. You can allow access to your videos in Settings.", comment: "Photo library authorization denied message"),
                         action: NSLocalizedString("authorization.deniedAction", value: "Open Settings", comment: "Photo library authorization denied action"))

        // Mostly for `notDetermined` but also as fallback if we land in `authorized` state.
        default:
            return .init(title: title,
                         message: NSLocalizedString("authorization.notDeterminedMessage", value: "Frame Grabber exports video frames as images. Get started by allowing access to your videos.", comment: "Photo library authorization default message"),
                         action: NSLocalizedString("authorization.notDeterminedAction", value: "Allow Access", comment: "Photo library authorization default action"))
        }
    }
}
