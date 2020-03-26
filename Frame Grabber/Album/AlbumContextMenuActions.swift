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
        UIAction(title: video.isFavorite ? UserText.unfavoriteAction : UserText.favoriteAction,
                 image: UIImage(systemName: video.isFavorite ? "heart.slash" : "heart"),
                 handler: action)
    }

    static func delete(action: @escaping (UIAction) -> ()) -> UIMenuElement {
        UIAction(title: UserText.deleteAction,
                 image: UIImage(systemName: "trash"),
                 attributes: .destructive,
                 handler: action)
    }
}

extension AlbumViewController {

    /// A view controller with an image view, sized to the full size of the image with an
    /// optional additional scale. The image is assumed to be sized with the screen's scale.
    func imagePreviewController(for sourceImageView: UIImageView?, scale: CGFloat = 1.2) -> UIViewController? {
        guard let sourceImageView = sourceImageView,
            let image = sourceImageView.image else { return nil }

        let imageSize = image.size.unscaledFromScreen
        let minimumSize = sourceImageView.bounds.size
        var size = imageSize

        if (imageSize.width < minimumSize.width) || (imageSize.height < minimumSize.height) {
            size = size.aspectFilling(minimumSize)
        }

        size = size.applying(.init(scaleX: scale, y: scale))

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
