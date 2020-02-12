import UIKit
import Photos

extension UIContextMenuConfiguration {

    static func menu(for video: PHAsset, previewProvider: (() -> UIViewController?)? = nil, toggleFavoriteAction: @escaping (UIAction) -> (), deleteAction: @escaping (UIAction) -> ()) -> UIContextMenuConfiguration {
        UIContextMenuConfiguration(identifier: video, previewProvider: previewProvider) { _ in
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

extension AlbumViewController {

    /// A view controller with an image view, sized to the full size of the image with an
    /// optional additional scale. The image is assumed to be sized with the screen's scale.
    func imagePreviewController(with image: UIImage?, scale: CGFloat = 1) -> UIViewController? {
        guard let image = image else { return nil }

        let size = image.size
            .unscaledFromScreen  // Get base size for image.
            .applying(.init(scaleX: scale, y: scale))

        let controller = UIViewController()
        controller.view.bounds.size = size
        controller.preferredContentSize = size

        let imageView = UIImageView(image: image)
        imageView.frame = controller.view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        controller.view.addSubview(imageView)

        return controller
    }
}
