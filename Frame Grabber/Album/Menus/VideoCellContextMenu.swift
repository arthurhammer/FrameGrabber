import UIKit
import Photos

struct VideoCellContextMenu {

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
            VideoContextMenuPreviewController(asset: video, initialImage: initialPreviewImage)
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
    
    private static func menu(
        for video: PHAsset,
        handler: @escaping (Selection) -> Void
    ) -> UIMenu {
        
        UIMenu(children: [
            UIAction(
                title: video.isFavorite ? UserText.unfavoriteAction : UserText.favoriteAction,
                image: UIImage(systemName: video.isFavorite ? "heart.slash" : "heart"),
                handler: { _ in handler(.favorite) }
            ),
            UIAction(
                title: UserText.deleteAction,
                image: UIImage(systemName: "trash"),
                attributes: .destructive,
                handler: { _ in handler(.delete) }
            )
        ])
    }
}
