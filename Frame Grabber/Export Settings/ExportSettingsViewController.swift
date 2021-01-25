import UIKit

protocol ExportSettingsViewControllerDelegate: class {
    func controller(_ controller: ExportSettingsViewController, didChangeExportAction: ExportAction)
    func controller(_ controller: ExportSettingsViewController, didChangeTimeFormat: TimeFormat)
}

class ExportSettingsViewController: UITableViewController {

    enum Section: Int {
        case metadata
        case format
        case compressionQuality
        case exportAction
    }
    
    weak var delegate: ExportSettingsViewControllerDelegate?

    let settings: UserDefaults = .standard

    @IBOutlet private var includeMetadataSwitch: UISwitch!
    @IBOutlet private var imageFormatControl: UISegmentedControl!
    @IBOutlet private var compressionQualityStepper: UIStepper!
    @IBOutlet private var compressionQualityLabel: UILabel!
    @IBOutlet private var compressionQualityStack: UIStackView!
    @IBOutlet private var selectedExportActionLabel: UILabel!
    @IBOutlet private var selectedTimeFormatLabel: UILabel!

    private lazy var compressionFormatter = NumberFormatter.percentFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fixCellHeight()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            updateViews(for: traitCollection)
        }
    }
    
    @IBSegueAction private func makeActionSettingsController(_ coder: NSCoder) -> ExportActionSettingsViewController? {
        let controller = ExportActionSettingsViewController(coder: coder)
        controller?.selectedAction = settings.exportAction
        controller?.didSelectAction = { [weak self] action in
            guard let self = self else  { return }
            self.settings.exportAction = action
            self.updateViews()
            self.delegate?.controller(self, didChangeExportAction: action)
        }
        return controller
    }
    
    @IBSegueAction private func makeTimeFormatSettingsController(_ coder: NSCoder) -> TimeFormatSettingsViewController? {
        let controller = TimeFormatSettingsViewController(coder: coder)
        controller?.selectedFormat = settings.timeFormat
        controller?.didSelectFormat = { [weak self] format in
            guard let self = self else  { return }
            self.settings.timeFormat = format
            self.updateViews()
            self.delegate?.controller(self, didChangeTimeFormat: format)
        }
        return controller
    }

    @IBAction private func done() {
        dismiss(animated: true)
    }

    @IBAction private func didUpdateIncludeMetadata(_ sender: UISwitch) {
        settings.includeMetadata = sender.isOn
    }
    
    @IBAction private func didUpdateImageFormat(_ sender: UISegmentedControl) {
        UISelectionFeedbackGenerator().selectionChanged()
        settings.imageFormat = ImageFormat.allCases[sender.selectedSegmentIndex]
    }

    @IBAction private func didChangeCompressionQuality(_ sender: UIStepper) {
        UISelectionFeedbackGenerator().selectionChanged()
        settings.compressionQuality = sender.value/100
        updateViews()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        (section == 0) ? Style.staticTableViewTopMargin : UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard Section(section) == .format else { return super.tableView(tableView, titleForFooterInSection: section) }

        return ImageFormat.heif.isEncodingSupported
            ? UserText.exportImageFormatHeifSupportedFooter
            : UserText.exportImageFormatHeifNotSupportedFooter
    }

    private func configureViews() {
        tableView.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
        tableView.backgroundColor = .clear

        compressionQualityLabel.font = UIFont.monospacedDigitSystemFont(forTextStyle: .body)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(done))
        
        configureImageFormatControl()
        updateViews(for: traitCollection)
        updateViews()
    }
        
    private func configureImageFormatControl() {
        let formats = ImageFormat.allCases
        imageFormatControl.removeAllSegments()
        
        formats.enumerated().forEach { (index, format) in
            imageFormatControl.insertSegment(
                withTitle: format.displayString,
                at: index,
                animated: false
            )
            
            imageFormatControl.setEnabled(format.isEncodingSupported, forSegmentAt: index)
        }
    }

    private func updateViews() {
        includeMetadataSwitch.isOn = settings.includeMetadata

        compressionQualityStepper.value = settings.compressionQuality*100
        compressionQualityLabel.text = compressionFormatter.string(from: settings.compressionQuality as NSNumber)
        
        let formatIndex = ImageFormat.allCases.firstIndex(of: settings.imageFormat)
        imageFormatControl.selectedSegmentIndex = formatIndex ?? 0
        
        selectedExportActionLabel.text = settings.exportAction.displayString
        selectedTimeFormatLabel.text = settings.timeFormat.displayString
    }
    
    private func updateViews(for traitCollection: UITraitCollection) {
        let isHuge = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        compressionQualityStack.axis = isHuge ? .vertical : .horizontal
    }

    private var firstAppereance = true

    private func fixCellHeight() {
        guard firstAppereance else { return }
        firstAppereance = false

        // For some reason, the first cell initially has a wrong height.
        DispatchQueue.main.async {
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        }
    }
}
