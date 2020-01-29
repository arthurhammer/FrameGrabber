import UIKit
import Photos

extension UIContextMenuConfiguration {

    static func menu(for video: PHAsset, toggleFavoriteAction: @escaping (UIAction) -> (), deleteAction: @escaping (UIAction) -> ()) -> UIContextMenuConfiguration {
        UIContextMenuConfiguration(identifier: video, previewProvider: nil) { _ in
            UIMenu(title: "", children: [
                .toggleFavorite(for: video, action: toggleFavoriteAction),
                .delete(action: deleteAction)
            ])
        }
    }
}

extension UIMenuElement {

    static func toggleFavorite(for video: PHAsset, action: @escaping (UIAction) -> ()) -> UIMenuElement {
        UIAction(title: video.isFavorite
                             ? NSLocalizedString("album.menu.unfavorite", value: "Unfavorite", comment: "Unfavorite video context action menu")
                             : NSLocalizedString("album.menu.favorite", value: "Favorite", comment: "Favorite video context action menu"),
                 image: UIImage(systemName: video.isFavorite ? "heart.slash" : "heart"),
                 handler: action)
    }

    static func delete(action: @escaping (UIAction) -> ()) -> UIMenuElement {
        UIAction(title: NSLocalizedString("album.menu.delete", value: "Delete", comment: "Delete video context action menu"),
                 image: UIImage(systemName: "trash"),
                 attributes: .destructive,
                 handler: action)
    }
}
