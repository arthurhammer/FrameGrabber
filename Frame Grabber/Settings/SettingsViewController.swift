import UIKit
import MessageUI

class SettingsViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    lazy var settings = UserDefaults.standard
    lazy var app = UIApplication.shared
    lazy var bundle = Bundle.main
    lazy var device = UIDevice.current

    var storeURL: URL? = nil
    var contactSubject = NSLocalizedString("Frame Grabber: Feedback", comment: "feedback email subject")
    var contactAddress = "framegrabber@ahammer.me"

    lazy var contactMessage = """
                              \n\n
                              \(bundle.formattedVersion)
                              \(device.systemName) \(device.systemVersion)
                              \(device.type ?? device.model)
                              """

    @IBOutlet private var contactButton: UIButton!
    @IBOutlet private var rateButton: UIButton!
    @IBOutlet private var metadataSwitch: UISwitch!
    @IBOutlet private var versionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    // MARK: Actions

    @IBAction private func done() {
        dismiss(animated: true)
    }

    @IBAction private func contact() {
        composeMail()
    }

    @IBAction private func rate() {
        // Ignore.
        guard let url = storeURL,
            app.canOpenURL(url) else { return }

        app.open(url)
    }

    @IBAction private func metadataOptionDidChange(_ sender: UISwitch) {
        settings.includeMetadata = sender.isOn
    }

    // MARK: Contact

    private func composeMail() {
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

    // MARK: View Setup

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    private func configureViews() {
        navigationController?.navigationBar.shadowImage = nil

        [contactButton, rateButton].forEach {
            $0?.layer.cornerRadius = 8
            $0?.backgroundColor = .mainTint
            $0?.tintColor = .white
        }

        metadataSwitch.isOn = settings.includeMetadata
        versionLabel.text = bundle.formattedVersion
    }
}

// MARK: - Util

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
