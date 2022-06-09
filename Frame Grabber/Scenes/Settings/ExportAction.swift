import UIKit

enum ExportAction: Int {
    case showShareSheet
    case saveToPhotos
}

extension ExportAction: CaseIterable, Hashable, Codable {}

extension ExportAction {
    
    var icon: UIImage? {
        switch self {
        case .showShareSheet: return UIImage(systemName: "square.and.arrow.up")
        case .saveToPhotos: return UIImage(systemName: "square.and.arrow.down")
        }
    }
    
    var displayString: String? {
        switch self {
        case .showShareSheet: return Localized.exportShowShareSheetAction
        case .saveToPhotos: return Localized.exportSaveToPhotosAction
        }
    }
}
