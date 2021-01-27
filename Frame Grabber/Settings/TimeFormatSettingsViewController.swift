import UIKit

class TimeFormatSettingsViewController: UITableViewController {
    
    var selectedFormat: TimeFormat = .minutesSecondsMilliseconds {
        didSet {
            guard isViewLoaded else { return }
            tableView.reloadData()
        }
    }
    
    var didSelectFormat: ((TimeFormat) -> ())?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fixCellHeight()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let format = TimeFormat(indexPath.item) else { return }
        
        selectedFormat = format
        tableView.reloadData()
        didSelectFormat?(format)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? TimeFormatSettingsCell,
              let action = TimeFormat(indexPath.item) else { return }

        cell.titleLabel.text = action.displayString
        cell.detailLabel.text = action.formatDisplayString
        cell.accessoryType = (action == selectedFormat) ? .checkmark : .none
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch selectedFormat {
        case .minutesSecondsMilliseconds: return UserText.exportSettingsMillisecondsFormatFooter
        case .minutesSecondsFrameNumber: return UserText.exportSettingsFrameNumberFormatFooter
        }
    }
    
    private func fixCellHeight() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

class TimeFormatSettingsCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var detailLabel: UILabel!
}
