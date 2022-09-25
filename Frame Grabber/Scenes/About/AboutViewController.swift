import MessageUI
import SafariServices
import Utility
import UIKit

@MainActor protocol AboutViewControllerDelegate: AnyObject {
    func controllerDidSelectPurchase(_ controller: AboutViewController)
}

final class AboutViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    enum Section: Int {
        case about
        case featured
    }
    
    weak var delegate: AboutViewControllerDelegate?

    private let app = UIApplication.shared
    private let bundle = Bundle.main
    private let device = UIDevice.current

    @IBOutlet private var supportTitleLabel: UILabel!
    @IBOutlet private var supportButtonsStack: UIStackView!
    @IBOutlet private var rateButton: UIButton!
    @IBOutlet private var purchaseButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateExpandedPreferredContentSize()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentContentSize(comparedTo: previousTraitCollection) {
            updateViews()
        }
    }
        
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let aboutSection = Section.about.rawValue
        let contactPath = IndexPath(row: 0, section: aboutSection)
        let privacyPolicyPath = IndexPath(row: 1, section: aboutSection)
        let showSourceCodePath = IndexPath(row: 2, section: aboutSection)

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
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard Section(section) == .about else { return super.tableView(tableView, titleForFooterInSection: section) }
        
        return String.localizedStringWithFormat(Localized.About.attributionFormat, bundle.version)
    }

    private func configureViews() {
        supportTitleLabel.font = .preferredFont(forTextStyle: .headline)

        var rateConfig = UIButton.Configuration.secondaryAction()
        rateConfig.title = Localized.About.rate
        rateButton.configuration = rateConfig

        var purchaseConfig = UIButton.Configuration.action()
        purchaseConfig.title = Localized.About.donate
        purchaseButton.configuration = purchaseConfig
        purchaseButton.configureWithDefaultShadow()
        purchaseButton.addAction(.init { [weak self] _ in
            guard let self else { return }
            self.delegate?.controllerDidSelectPurchase(self)
        }, for: .primaryActionTriggered)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(done))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: Localized.About.shareApp,
            image: UIImage(systemName: "square.and.arrow.up"),
            primaryAction: UIAction { [weak self] _ in self?.shareApp() },
            menu: nil
        )
        
        updateViews()
    }
    
    private func updateViews() {
        supportButtonsStack.axis = traitCollection.hasHugeContentSize ? .vertical : .horizontal
    }
}

// MARK: - Actions

extension AboutViewController {

    @IBAction private func done() {
        dismiss(animated: true)
    }
    
    private func shareApp() {
        guard let url = About.storeURL?.absoluteString else { return }
        let shareText = "\(Localized.About.shareAppText)\n\(url)"
        let shareController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        present(shareController, animated: true)
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
        mailController.setSubject(Localized.About.emailSubject)
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
        safariController.modalPresentationStyle = .automatic
        safariController.preferredControlTintColor = .accent
        present(safariController, animated: true)
    }
}
