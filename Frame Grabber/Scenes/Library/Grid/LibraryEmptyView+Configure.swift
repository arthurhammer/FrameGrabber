import UIKit

extension LibraryEmptyView {
    func configure(with filter: PhotoLibraryFilter) {
        switch filter {
        case .videoAndLivePhoto:
            titleLabel.text = Localized.albumEmptyAny
            imageView.image = UIImage(systemName: "photo.on.rectangle.angled")  // Images follow filter menu (but filled)
        case .video:
            titleLabel.text = Localized.albumEmptyVideos
            imageView.image = UIImage(systemName: "video.fill")
        case .livePhoto:
            titleLabel.text = Localized.albumEmptyLive
            imageView.image = UIImage(systemName: "livephoto")
        }
    }
}
