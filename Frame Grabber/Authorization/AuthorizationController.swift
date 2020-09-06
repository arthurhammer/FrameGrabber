import UIKit
import Photos
import SafariServices

class AuthorizationController: UIViewController {

    static var needsAuthorization: Bool {
        let status = PHPhotoLibrary.readWriteAuthorizationStatus
        return [.notDetermined, .denied, .restricted].contains(status)
    }

    var didAuthorizeHandler: (() -> ())?

    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var scrollViewSeparator: UIView!
    @IBOutlet private var authorizationMessageLabel: UILabel!
    @IBOutlet private var actionButton: UIButton!
    @IBOutlet private var privacyButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        DispatchQueue.main.async {
            self.updateSeparator()
        }
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
        scrollView.delegate = self
        actionButton.configureAsActionButton()
        privacyButton.configureDynamicTypeLabel()

        updateViews()
        updateSeparator()
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

    private func updateSeparator() {
        guard let contentView = scrollView.subviews.first else { return  }

        let contentRect = scrollView.convert(contentView.frame, to: view)
        scrollViewSeparator.isHidden = !contentRect.intersects(actionButton.superview!.frame)
    }
}

// MARK: - UIScrollViewDelegate

extension AuthorizationController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateSeparator()
    }
}
