import UIKit

class EmptyAlbumView: UILabel {

    var isEmpty: Bool = true {
        didSet { updateViews() }
    }

    var type: VideoType = .any {
        didSet { updateViews() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViews()
    }

    private func configureViews() {
        font = .preferredFont(forTextStyle: .title1, weight: .semibold)
        adjustsFontForContentSizeCategory = true
        textColor = .secondaryLabel
        textAlignment = .center
        updateViews()
    }

    private func updateViews() {
        text = isEmpty ? type.emptyAlbumMessage : nil
    }
}

private extension VideoType {

    var emptyAlbumMessage: String {
        switch self {
        case .any: return NSLocalizedString("album.empty.any", value: "No Videos or Live Photos", comment: "Empty album message")
        case .video: return NSLocalizedString("album.empty.video", value: "No Videos", comment: "No videos in album message")
        case .livePhoto: return NSLocalizedString("album.empty.livePhoto", value: "No Live Photos", comment: "No live photos in album message")
        }
    }
}
