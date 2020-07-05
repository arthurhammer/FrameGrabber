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
    @IBOutlet private var compressionQualitySlider: UISlider!
    @IBOutlet private var compressionQualityLabel: UILabel!

    private let heifIndexPath = IndexPath(row: 0, section: 1)
    private let jpgIndexPath = IndexPath(row: 1, section: 1)

    private lazy var compressionFormatter = NumberFormatter.percentFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    @IBAction private func done() {
        dismiss(animated: true)
    }

    @IBAction private func didUpdateIncludeMetadata(_ sender: UISwitch) {
        settings.includeMetadata = sender.isOn
    }

    @IBAction func didChangeCompressionQuality() {
        let value = Double(compressionQualitySlider.value).rounded(toDecimalDigits: 2)
        settings.compressionQuality = value
        updateViews()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath {
        case heifIndexPath where UserDefaults.isHeifSupported:
            settings.imageFormat = .heif
        default:
            settings.imageFormat = .jpg
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
        if Section(section) == .format && UserDefaults.isHeifSupported { return nil }
        return super.tableView(tableView, titleForFooterInSection: section)
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

        compressionQualitySlider.value = Float(settings.compressionQuality)
        compressionQualityLabel.text = compressionFormatter.string(from: settings.compressionQuality as NSNumber)

        let isHeif = settings.imageFormat == .heif
        heifCell.accessoryType = isHeif ? .checkmark : .none
        jpgCell.accessoryType = isHeif ? .none : .checkmark

        if !UserDefaults.isHeifSupported {
            heifCell.accessoryType = .none
            heifLabel.textColor = Style.Color.disabledLabel
        }
    }
}

private extension Double {
    /// Rounds the double to decimal places value.
    func rounded(toDecimalDigits digits: Int) -> Self {
        let divisor = pow(10.0, Double(digits))
        return (self * divisor).rounded() / divisor
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
