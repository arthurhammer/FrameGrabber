import InAppPurchase
import MessageUI
import SafariServices
import UIKit

class AboutTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    let app = UIApplication.shared
    let bundle = Bundle.main
    let device = UIDevice.current

    var hasPurchased: Bool {
        paymentsManager.hasPurchasedProduct(withId: inAppPurchaseId)
    }

    private let paymentsManager = StorePaymentsManager.shared
    private let inAppPurchaseId = About.inAppPurchaseIdentifier
    private let reviewURL = About.storeReviewURL
    private let contactSubject = UserText.aboutContactSubject

    private lazy var contactMessage = """
    \n\n
    \(bundle.longFormattedVersion)
    \(device.systemName) \(device.systemVersion)
    \(device.type ?? device.model)
    """

    @IBOutlet private var rateButton: UIButton!
    @IBOutlet private var iceCreamButton: UIButton!
    @IBOutlet private var versionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateViews()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let sendFeedpackPath = IndexPath(row: 0, section: 1)
        let privacyPolicyPath = IndexPath(row: 1, section: 1)
        let showSourceCodePath = IndexPath(row: 2, section: 1)

        switch indexPath {
        case sendFeedpackPath: sendFeedback()
        case privacyPolicyPath: showPrivacyPolicy()
        case showSourceCodePath: showSourceCode()
        default: break
        }
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        tableView.cellForRow(at: indexPath)?.accessoryType != .some(.none)
    }

    private func configureViews() {
        tableView.backgroundColor = .clear

        rateButton.tintColor = .systemGroupedBackground
        rateButton.backgroundColor = Style.Color.mainTint
        rateButton.layer.cornerRadius = Style.Size.buttonCornerRadius

        versionLabel.text = String.localizedStringWithFormat(UserText.aboutVersionFormat, bundle.shortFormattedVersion)

        updateViews()
    }

    private func updateViews() {
        let title = hasPurchased ? UserText.aboutPurchasedButton : UserText.aboutNotPurchasedButton
        iceCreamButton.setTitle(title, for: .normal)
    }
}

// MARK: - Actions

extension AboutTableViewController {

    @IBAction private func rate() {
        guard let url = reviewURL,
            app.canOpenURL(url) else { return }

        app.open(url)
    }
    
    func sendFeedback() {
        guard MFMailComposeViewController.canSendMail() else {
            presentAlert(.mailNotAvailable(contactAddress: About.contactAddress))
            return
        }

        let mailController = MFMailComposeViewController()
        mailController.view.tintColor = Style.Color.mainTint
        mailController.mailComposeDelegate = self
        mailController.setToRecipients([About.contactAddress])
        mailController.setSubject(contactSubject)
        mailController.setMessageBody(contactMessage, isHTML: false)

        present(mailController, animated: true)
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true)
    }

    func showSourceCode() {
        guard let url = About.sourceCodeURL else { return }
        showURL(url)
    }

    func showPrivacyPolicy() {
        guard let url = About.PrivacyPolicy.preferred else { return }
        showURL(url)
    }

    private func showURL(_ url: URL) {
        let safariController = SFSafariViewController(url: url)
        safariController.preferredControlTintColor = Style.Color.mainTint
        present(safariController, animated: true)
    }
}
