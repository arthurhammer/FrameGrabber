import UIKit

extension LibraryMenu {
    struct Limited {
        
        enum Selection: String, CaseIterable {
            case addMorePhotos
            case showSettings
        }
        
        static func menu(selection: @escaping (Selection) -> Void) -> UIMenu {
            let items = Selection.allCases.map { item in
                UIAction(title: item.title) { _ in
                    UISelectionFeedbackGenerator().selectionChanged()
                    selection(item)
                }
            }
            
            return UIMenu(children: items)
        }
    }
}

extension LibraryMenu.Limited.Selection {
    var title: String {
        switch self {
        case .addMorePhotos:
            return Localized.libraryLimitedSelectMorePhotosMenuAction
        case .showSettings:
            return Localized.libraryLimitedOpenSettingsMenuAction
        }
    }
}
