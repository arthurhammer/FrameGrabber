import UIKit
import Photos

struct AlbumCellContextMenu {

    enum Selection {
        case favorite
        case delete
    }

    /// - Parameter indexPath: Passed as the identifier of the configuration.
    static func menu(
        for video: PHAsset,
        at indexPath: IndexPath,
        previewProvider: (() -> UIViewController?)? = nil,
        handler: @escaping (Selection) -> Void
    ) -> UIContextMenuConfiguration {

        UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: previewProvider) { _ in
            UIMenu(title: "", children: [
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
