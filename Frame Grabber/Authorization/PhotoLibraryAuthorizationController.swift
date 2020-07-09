import UIKit
import Photos
import SafariServices

class PhotoLibraryAuthorizationController: UIViewController {

    static var needsAuthorization: Bool {
        let status = PHPhotoLibrary.readWriteAuthorizationStatus
        return [.notDetermined, .denied, .restricted].contains(status)
    }

    var didAuthorizeHandler: (() -> ())?

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var button: UIButton!
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
        safariController.preferredControlTintColor = Style.Color.mainTint
        present(safariController, animated: true)
    }

    private func configureViews() {
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title1, size: 36, weight: .semibold)

        button.tintColor = .systemBackground
        button.backgroundColor = Style.Color.mainTint
        button.layer.cornerRadius = Style.Size.buttonCornerRadius
        button.layer.cornerCurve = .continuous

        updateViews()
    }

    private func updateViews() {
        titleLabel.text = UserText.authorizationTitle

        switch PHPhotoLibrary.readWriteAuthorizationStatus {
        case .denied, .restricted:
            messageLabel.text = UserText.authorizationDeniedMessage
            button.setTitle(UserText.authorizationDeniedAction, for: .normal)

        // For `notDetermined` but also as fallback if we land in `authorized`/`limited` state.
        default:
            messageLabel.text = UserText.authorizationUndeterminedMessage
            button.setTitle(UserText.authorizationUndeterminedAction, for: .normal)
        }
    }
}
