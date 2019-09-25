import UIKit

class SettingsViewController: UITableViewController {

    lazy var settings = UserDefaults.standard

    @IBOutlet private var metadataSwitch: UISwitch!
    @IBOutlet private var imageFormatLabel: UILabel!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateViews()
    }

    @IBAction private func done() {
        dismiss(animated: true)
    }

    @IBAction private func metadataOptionDidChange(_ sender: UISwitch) {
        settings.includeMetadata = sender.isOn
    }

    private func updateViews() {
        metadataSwitch.isOn = settings.includeMetadata

        if let quality = NumberFormatter.percentFormatter().string(from: settings.compressionQuality as NSNumber) {
            imageFormatLabel.text = "\(settings.imageFormat.displayString) (\(quality))"
        } else {
            imageFormatLabel.text = settings.imageFormat.displayString
        }
    }
}
