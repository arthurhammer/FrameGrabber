import UIKit

struct LibraryImportMenu {

    enum Selection: CaseIterable {
        case addMorePhotos
        case file
        case camera
        
        var icon: UIImage? {
            switch self {
            case .file: return UIImage(systemName: "folder")
            case .camera: return UIImage(systemName: "camera")
            case .addMorePhotos: return UIImage(systemName: "photo.on.rectangle.angled")
            }
        }
        
        var title: String {
            switch self {
            case .file: return UserText.libraryImportFileMenuAction
            case .camera: return UserText.libraryImportCameraMenuAction
            case .addMorePhotos: return UserText.libraryImportSelectMorePhotosMenuAction
            }
        }
    }

    @available(iOS 14, *)
    static func menu(isLibraryLimited: Bool, selection: @escaping (Selection) -> Void) -> UIMenu {
        let options = isLibraryLimited
            ? Selection.allCases
            : Selection.allCases.filter { $0 != .addMorePhotos }
        
        let title = isLibraryLimited ? UserText.libraryImportLimitedAuthorizationTitle : ""
        
        let actions = options.map { option in
            UIAction(title: option.title, image: option.icon) { _ in selection(option) }
        }
        
        return UIMenu(title: title, children: actions.reversed())
    }

    @available(iOS, obsoleted: 14, message: "Use context menus.")
    static func alertController(selection: @escaping (Selection) -> Void) -> UIAlertController {
        let options = Selection.allCases.filter { $0 != .addMorePhotos }

        let actions = options.map { option in
            UIAlertAction(title: option.title, style: .default, handler: { _ in selection(option) })
        }

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addActions(actions)
        alert.addAction(.cancel())
        return alert
    }
    
    @available(iOS, obsoleted: 14, message: "Use context menus.")
    static func presentAsAlert(
        from presenter: UIViewController,
        sourceView: UIView,
        selection: @escaping (Selection) -> Void
    ) {
        let alert = alertController(selection: selection)
        alert.popoverPresentationController?.sourceView = sourceView
        presenter.present(alert, animated: true)
    }
}
