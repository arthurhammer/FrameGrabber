import UIKit

class ExportSettingsViewController: UITableViewController {

    enum Section: Int {
        case metadata
        case format
        case compressionQuality
    }

    var settings: UserDefaults = .standard

    @IBOutlet private var includeMetadataSwitch: UISwitch!
    @IBOutlet private var heifCell: UITableViewCell!
    @IBOutlet private var heifLabel: UILabel!
    @IBOutlet private var jpgCell: UITableViewCell!
    @IBOutlet private var compressionQualityStepper: UIStepper!
    @IBOutlet private var compressionQualityLabel: UILabel!

    private let heifIndexPath = IndexPath(row: 0, section: 1)
    private let jpgIndexPath = IndexPath(row: 1, section: 1)

    private lazy var compressionFormatter = NumberFormatter.percentFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fixCellHeight()
    }

    @IBAction private func done() {
        dismiss(animated: true)
    }

    @IBAction private func didUpdateIncludeMetadata(_ sender: UISwitch) {
        settings.includeMetadata = sender.isOn
    }

    @IBAction func didChangeCompressionQuality() {
        settings.compressionQuality = compressionQualityStepper.value/100
        updateViews()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath {
        case heifIndexPath where UserDefaults.isHeifSupported:
            settings.imageFormat = .heif
        default:
            settings.imageFormat = .jpeg
        }

        updateViews()
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        ((indexPath == heifIndexPath) && UserDefaults.isHeifSupported) || (indexPath == jpgIndexPath)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = Section(section)?.title else { return nil }
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: ExportSettingsSectionHeader.name) as? ExportSettingsSectionHeader else { fatalError("Wrong view id or type.") }

        view.titleLabel.text = title
        view.hasPreviousFooter = self.tableView(tableView, titleForFooterInSection: section-1) != nil

        return view
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard Section(section) == .format else { return super.tableView(tableView, titleForFooterInSection: section) }

        return UserDefaults.isHeifSupported
            ? UserText.exportImageFormatHeifSupportedFooter
            : UserText.exportImageFormatHeifNotSupportedFooter
    }

    private func configureViews() {
        tableView.register(ExportSettingsSectionHeader.nib, forHeaderFooterViewReuseIdentifier: ExportSettingsSectionHeader.name)

        tableView.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
        tableView.backgroundColor = .clear

        compressionQualityLabel.font = UIFont.monospacedDigitSystemFont(forTextStyle: .body)
        updateViews()
    }

    private func updateViews() {
        includeMetadataSwitch.isOn = settings.includeMetadata

        compressionQualityStepper.value = settings.compressionQuality*100
        compressionQualityLabel.text = compressionFormatter.string(from: settings.compressionQuality as NSNumber)

        let isHeif = settings.imageFormat == .heif
        heifCell.accessoryType = isHeif ? .checkmark : .none
        jpgCell.accessoryType = isHeif ? .none : .checkmark

        if !UserDefaults.isHeifSupported {
            heifCell.accessoryType = .none
            heifLabel.textColor = .disabledLabel
        }
    }

    private var firstAppereance = true

    private func fixCellHeight() {
        guard firstAppereance else { return }
        firstAppereance = false
        // For some reason, the first cell initially has a wrong height (iOS 13 only).
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
    }
}

extension ExportSettingsViewController.Section {
    var title: String? {
        switch self {
        case .metadata: return nil
        case .format: return UserText.exportImageFormatSection
        case .compressionQuality: return UserText.exportCompressionQualitySection
        }
    }
}
