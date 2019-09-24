import UIKit

class ImageFormatViewController: UITableViewController {

    var settings: UserDefaults = .standard

    @IBOutlet private var heifCell: UITableViewCell!
    @IBOutlet private var jpgCell: UITableViewCell!
    @IBOutlet private var compressionQualitySlider: UISlider!
    @IBOutlet private var compressionQualityLabel: UILabel!

    private let heifIndexPath = IndexPath(row: 0, section: 0)
    private let jpgIndexPath = IndexPath(row: 1, section: 0)

    private lazy var compressionFormatter = NumberFormatter.percentFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        updateViews()
    }

    private func updateViews() {
        compressionQualitySlider.value = Float(settings.compressionQuality)
        compressionQualityLabel.text = compressionFormatter.string(from: settings.compressionQuality as NSNumber)

        let isHeif = settings.imageFormat == .heif
        heifCell.accessoryType = isHeif ? .checkmark : .none
        jpgCell.accessoryType = isHeif ? .none : .checkmark

        if !UserDefaults.isHeifSupported {
            heifCell.accessoryType = .none
            heifCell.textLabel?.textColor = Style.Color.disabledLabel
        }
    }

    @IBAction private func done() {
        dismiss(animated: true)
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

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == 0 else { return nil }
        let message = NSLocalizedString("settings.format.noheif", value: "The HEIF format is not available on this device.", comment: "The HEIF image format is not support message.")
        return UserDefaults.isHeifSupported ? nil : message
    }
}

private extension Double {
    /// Rounds the double to decimal places value.
    func rounded(toDecimalDigits digits: Int) -> Self {
        let divisor = pow(10.0, Double(digits))
        return (self * divisor).rounded() / divisor
    }
}
