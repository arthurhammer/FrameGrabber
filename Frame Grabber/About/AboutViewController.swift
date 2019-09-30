import UIKit
import MessageUI
import SafariServices

class AboutViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    let app = UIApplication.shared
    let bundle = Bundle.main
    let device = UIDevice.current

    static let privacyPolicyURL = URL(string: "https://arthurhammer.github.io/FrameGrabber")
    let storeURL = URL(string: "itms-apps://itunes.apple.com/app/id1434703541?ls=1&mt=8&action=write-review")
    let sourceCodeURL = URL(string: "https://github.com/arthurhammer/FrameGrabber")

    let contactSubject = NSLocalizedString("settings.emailSubject", value: "Frame Grabber: Feedback", comment: "Feedback email subject")
    let contactAddress = "hi@arthurhammer.de"
    lazy var contactMessage = """
                           \n\n
                           \(bundle.formattedVersion)
                           \(device.systemName) \(device.systemVersion)
                           \(device.type ?? device.model)
                           """

    @IBOutlet private var versionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        versionLabel.text = bundle.formattedVersion
    }

    override func viewDidLayoutSubviews() {
         super.viewDidLayoutSubviews()
         updateHeaderAndFooter()
     }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let sendFeedpackPath = IndexPath(row: 0, section: 0)
        let rateAppPath = IndexPath(row: 1, section: 0)
        let showSourceCodePath = IndexPath(row: 0, section: 1)
        let privacyPolicyPath = IndexPath(row: 1, section: 1)

        switch indexPath {
        case sendFeedpackPath: sendFeedback()
        case rateAppPath: rate()
        case showSourceCodePath: showSourceCode()
        case privacyPolicyPath: showPrivacyPolicy()
        default: break
        }
    }
}

extension AboutViewController {

    @IBAction private func done() {
        dismiss(animated: true)
    }

    func sendFeedback() {
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

    func rate() {
        guard let url = storeURL,
            app.canOpenURL(url) else { return }

        app.open(url)
    }

    func showSourceCode() {
        guard let url = sourceCodeURL else { return }
        present(SFSafariViewController(url: url), animated: true)
    }

    func showPrivacyPolicy() {
        guard let url = AboutViewController.privacyPolicyURL else { return }
        present(SFSafariViewController(url: url), animated: true)
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
