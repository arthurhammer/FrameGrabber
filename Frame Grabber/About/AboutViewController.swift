import InAppPurchase
import MessageUI
import SafariServices
import UIKit

class AboutViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    enum Section: Int {
        case featured
        case about
    }

    let app = UIApplication.shared
    let bundle = Bundle.main
    let device = UIDevice.current

    @IBOutlet private var rateButton: UIButton!
    @IBOutlet private var purchaseButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
            self?.updateNavigationBar()
        }, completion: { [weak self] _ in
            self?.updateNavigationBar()
        })
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let contactPath = IndexPath(row: 0, section: 1)
        let privacyPolicyPath = IndexPath(row: 1, section: 1)
        let showSourceCodePath = IndexPath(row: 2, section: 1)

        switch indexPath {
        case contactPath: contact()
        case privacyPolicyPath: showPrivacyPolicy()
        case showSourceCodePath: showSourceCode()
        default: break
        }
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        tableView.cellForRow(at: indexPath)?.accessoryType != .some(.none)
    }

    private func configureViews() {
        rateButton.layer.cornerRadius = Style.buttonCornerRadius
        rateButton.layer.cornerCurve = .continuous

        purchaseButton.backgroundColor = UIColor.accent?.withAlphaComponent(0.1)
        purchaseButton.layer.cornerRadius = Style.buttonCornerRadius
        purchaseButton.layer.cornerCurve = .continuous
    }

    private func updateNavigationBar() {
        let bar = navigationController?.navigationBar
        bar?.tintColor = nil
        bar?.shadowImage = nil
        bar?.setBackgroundImage(nil, for: .default)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        (section == 0) ? Style.staticTableViewTopMargin : UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch Section(section) {
        case .about:
            return String.localizedStringWithFormat(UserText.aboutVersionFormat, bundle.shortFormattedVersion)
        default:
            return nil
        }
    }
}

// MARK: - Actions

extension AboutViewController {

    @IBAction private func done() {
        dismiss(animated: true)
    }

    @IBAction private func rate() {
        guard let url = About.storeReviewURL,
            app.canOpenURL(url) else { return }

        app.open(url)
    }
    
    private func contact() {
        guard MFMailComposeViewController.canSendMail() else {
            presentAlert(.mailNotAvailable(contactAddress: About.contactAddress))
            return
        }

        let contactMessage = """
        \n\n
        \(bundle.longFormattedVersion)
        \(device.systemName) \(device.systemVersion)
        \(device.type ?? device.model)
        """

        let mailController = MFMailComposeViewController()
        mailController.view.tintColor = .accent
        mailController.mailComposeDelegate = self
        mailController.setToRecipients([About.contactAddress])
        mailController.setSubject(UserText.aboutContactSubject)
        mailController.setMessageBody(contactMessage, isHTML: false)

        present(mailController, animated: true)
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true)
    }

    private func showSourceCode() {
        guard let url = About.sourceCodeURL else { return }
        showURL(url)
    }

    private func showPrivacyPolicy() {
        guard let url = About.PrivacyPolicy.preferred else { return }
        showURL(url)
    }

    private func showURL(_ url: URL) {
        let safariController = SFSafariViewController(url: url)
        safariController.preferredControlTintColor = .accent
        present(safariController, animated: true)
    }
}
