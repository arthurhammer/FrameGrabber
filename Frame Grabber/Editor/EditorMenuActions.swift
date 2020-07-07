import UIKit

struct EditorMenuActions {

    /// The segue identifiers for the more menu actions.
    enum SegueId: String {
        case metadata = "Metadata"
        case exportSettings = "ExportSettings"
    }

    /// - Parameter handler: Is called with the segue identifier of the chosen menu item.
    @available(iOS 14, *)
    static func moreMenu(handler: @escaping (SegueId) -> Void) -> UIMenu {
        UIMenu(title: "", children: [
            UIAction(
                title: UserText.editorViewMetadataAction,
                image: UIImage(systemName: "paperclip"),
                handler: { _ in handler(.metadata) }
            ),
            UIAction(
                title: UserText.editorViewExportSettingsAction,
                image: UIImage(systemName: "gear"),
                handler: { _ in handler(.exportSettings) }
            )
        ])
    }

    /// - Parameter handler: Is called with the segue identifier of the chosen menu item.
    static func moreAlertController(handler: @escaping (SegueId) -> Void) -> UIAlertController {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        controller.addActions(
            UIAlertAction(
                title: UserText.editorViewMetadataAction,
                style: .default,
                handler: { _ in handler(.metadata) }
            ),
            UIAlertAction(
                title: UserText.editorViewExportSettingsAction,
                style: .default,
                handler: { _ in handler(.exportSettings) }
            ),
            .cancel()
        )

        return controller
    }
}
