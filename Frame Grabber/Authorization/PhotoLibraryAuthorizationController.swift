import UIKit
import Photos
import SafariServices

class PhotoLibraryAuthorizationController: UIViewController {

    static var needsAuthorization: Bool {
        let status = PHPhotoLibrary.readWriteAuthorizationStatus
        return [.notDetermined, .denied, .restricted].contains(status)
    }

    var didAuthorizeHandler: (() -> ())?

    @IBOutlet private var authorizationMessageLabel: UILabel!
    @IBOutlet private var actionButton: UIButton!
    @IBOutlet private var privacyButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    @IBAction private func requestAuthorization() {
        PHPhotoLibrary.requestReadWriteAuthorization(openingSettingsIfNeeded: true) { status, _ in
            self.updateViews()

            if status == .authorized {
                self.didAuthorizeHandler?()
            }
        }
    }

    @IBAction private func showPrivacyPolicy() {
        guard let url = About.PrivacyPolicy.preferred else { return }
        let safariController = SFSafariViewController(url: url)
        safariController.preferredControlTintColor = .accent
        present(safariController, animated: true)
    }

    private func configureViews() {
        actionButton.configureAsActionButton()
        privacyButton.configureDynamicTypeLabel()

        updateViews()
    }

    private func updateViews() {
        switch PHPhotoLibrary.readWriteAuthorizationStatus {
        case .denied, .restricted:
            authorizationMessageLabel.text = UserText.authorizationDeniedMessage
            actionButton.setTitle(UserText.authorizationDeniedAction, for: .normal)

        // For `notDetermined` but also as fallback if we land in `authorized`/`limited` state.
        default:
            authorizationMessageLabel.text = UserText.authorizationUndeterminedMessage
            actionButton.setTitle(UserText.authorizationUndeterminedAction, for: .normal)
        }
    }
}
