import UIKit

class ExportActionSettingsViewController: UITableViewController {
    
    var selectedAction: ExportAction = .showShareSheet {
        didSet {
            guard isViewLoaded else { return }
            tableView.reloadData()
        }
    }
    
    var didSelectAction: ((ExportAction) -> ())?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let action = ExportAction(indexPath.item) else { return }
        
        selectedAction = action
        tableView.reloadData()
        didSelectAction?(action)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? ExportActionSettingsCell,
              let action = ExportAction(indexPath.item) else { return }

        cell.titleLabel.text = action.displayString
        cell.iconView.image = action.icon
        cell.accessoryType = (action == selectedAction) ? .checkmark : .none
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch selectedAction {
        case .showShareSheet: return Localized.exportSettingsShowShareSheetFooter
        case .saveToPhotos: return Localized.exportSettingsSaveToPhotosFooter
        }
    }
}

class ExportActionSettingsCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var iconView: UIImageView!
}
