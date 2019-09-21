import UIKit
import MessageUI
import SafariServices

class SettingsViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    lazy var settings = UserDefaults.standard
    lazy var app = UIApplication.shared
    lazy var bundle = Bundle.main
    lazy var device = UIDevice.current

    static var privacyPolicyURL = URL(string: "https://arthurhammer.github.io/FrameGrabber")
    lazy var storeURL = URL(string: "itms-apps://itunes.apple.com/app/id1434703541?ls=1&mt=8&action=write-review")
    lazy var sourceCodeURL = URL(string: "https://github.com/arthurhammer/FrameGrabber")

    lazy var contactSubject = NSLocalizedString("settings.emailSubject", value: "Frame Grabber: Feedback", comment: "Feedback email subject")
    lazy var contactAddress = "hi@arthurhammer.de"
    lazy var contactMessage = """
                              \n\n
                              \(bundle.formattedVersion)
                              \(device.systemName) \(device.systemVersion)
                              \(device.type ?? device.model)
                              """

    @IBOutlet private var metadataSwitch: UISwitch!
    @IBOutlet private var versionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderAndFooter()
    }

    // MARK: Actions

    @IBAction private func done() {
        dismiss(animated: true)
    }

    @IBAction private func metadataOptionDidChange(_ sender: UISwitch) {
        settings.includeMetadata = sender.isOn
    }

    private func sendFeedback() {
        guard MFMailComposeViewController.canSendMail() else {
            presentAlert(.mailNotAvailable(contactAddress: contactAddress))
            return
        }

        let mailController = MFMailComposeViewController()
        mailController.mailComposeDelegate = self
        mailController.setToRecipients([contactAddress])
        mailController.setSubject(contactSubject)
        mailController.setMessageBody(contactMessage, isHTML: false)

        present(mailController, animated: true)
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true)
    }

    private func rate() {
        // Ignore.
        guard let url = storeURL,
            app.canOpenURL(url) else { return }

        app.open(url)
    }

    private func showSourceCode() {
        guard let url = sourceCodeURL else { return }
        present(SFSafariViewController(url: url), animated: true)
    }

    private func showPrivacyPolicy() {
        guard let url = SettingsViewController.privacyPolicyURL else { return }
        present(SFSafariViewController(url: url), animated: true)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let supportSection = 1
        let sendFeedpackPath = IndexPath(row: 0, section: supportSection)
        let rateAppPath = IndexPath(row: 1, section: supportSection)
        let showSourceCodePath = IndexPath(row: 2, section: supportSection)
        let privacyPolicyPath = IndexPath(row: 3, section: supportSection)

        switch indexPath {
        case sendFeedpackPath: sendFeedback()
        case rateAppPath: rate()
        case showSourceCodePath: showSourceCode()
        case privacyPolicyPath: showPrivacyPolicy()
        default: break
        }
    }

    // MARK: View Setup

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    private func configureViews() {
        navigationController?.navigationBar.shadowImage = nil

        metadataSwitch.isOn = settings.includeMetadata
        versionLabel.text = bundle.formattedVersion
    }
}

// MARK: - Util

private extension UITableViewController {
    /// Size footer/header views according to AutoLayout.
    func updateHeaderAndFooter() {
        if let newHeight = autoLayoutHeight(for: tableView.tableHeaderView) {
            tableView.tableHeaderView?.bounds.size.height = newHeight
            tableView.tableHeaderView = tableView.tableHeaderView
        }

        if let newHeight = autoLayoutHeight(for: tableView.tableFooterView) {
            tableView.tableFooterView?.bounds.size.height = newHeight
            tableView.tableFooterView = tableView.tableFooterView
        }
    }

    func autoLayoutHeight(for view: UIView?) -> CGFloat? {
        guard let view = view else { return nil }
        let newHeight = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        return (newHeight != view.bounds.height) ? newHeight : nil
    }
}

private extension UIDevice {
    /// Device type, e.g. "iPhone7,2".
    var type: String? {
        // From the world wide webs.
        var systemInfo = utsname()
        uname(&systemInfo)

        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0)
            }
        }
    }
}
