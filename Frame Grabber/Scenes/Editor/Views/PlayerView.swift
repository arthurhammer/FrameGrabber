import UIKit
import AVFoundation

final class PlayerView: UIView {

    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
    
    var posterImage: UIImage? {
        get { posterImageView.image }
        set { posterImageView.image = newValue }
    }

    private lazy var posterImageView: UIImageView = {
        let imageView = UIImageView(frame: bounds)
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        insertSubview(imageView, at: 0)
        return imageView
    }()
    
    private var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}
