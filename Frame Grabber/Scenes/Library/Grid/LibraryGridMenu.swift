import UIKit
import Photos

struct LibraryGridMenu {

    enum Selection {
        case favorite
        case delete
    }

    /// - Parameter video: Passed as the identifier of the configuration.
    static func configuration(
        for video: PHAsset,
        initialPreviewImage: UIImage?,
        handler: @escaping (Selection) -> Void
    ) -> UIContextMenuConfiguration {
        
        let previewProvider = {
            LibraryGridMenuPreviewController(asset: video, initialImage: initialPreviewImage)
        }
        
        let menuProvider = { (_: Any) in
            menu(for: video, handler: handler)
        }

        return UIContextMenuConfiguration(
            identifier: video,
            previewProvider: previewProvider,
            actionProvider: menuProvider
        )
    }
    
    private static func menu(for video: PHAsset, handler: @escaping (Selection) -> Void) -> UIMenu {
        UIMenu(title: menuTitle(for: video), children: [
            UIAction(
                title: video.isFavorite ? Localized.unfavoriteAction : Localized.favoriteAction,
                image: UIImage(systemName: video.isFavorite ? "heart.slash" : "heart"),
                handler: { _ in handler(.favorite) }
            ),
            UIAction(
                title: Localized.deleteAction,
                image: UIImage(systemName: "trash"),
                attributes: .destructive,
                handler: { _ in handler(.delete) }
            )
        ])
    }
    
    private static func menuTitle(for video: PHAsset) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return video.creationDate.flatMap(formatter.string(from:)) ?? ""
    }
}
