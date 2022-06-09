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
            case .file: return Localized.libraryImportFileMenuAction
            case .camera: return Localized.libraryImportCameraMenuAction
            case .addMorePhotos: return Localized.libraryImportSelectMorePhotosMenuAction
            }
        }
    }

    static func menu(isLibraryLimited: Bool, selection: @escaping (Selection) -> Void) -> UIMenu {
        let options = isLibraryLimited
            ? Selection.allCases
            : Selection.allCases.filter { $0 != .addMorePhotos }
        
        let title = isLibraryLimited ? Localized.libraryImportLimitedAuthorizationTitle : ""
        
        let actions = options.map { option in
            UIAction(title: option.title, image: option.icon) { _ in selection(option) }
        }
        
        return UIMenu(title: title, children: actions.reversed())
    }
}
