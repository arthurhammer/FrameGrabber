import UIKit
import AVFoundation

class PlayerView: UIView {

    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    private(set) lazy var posterImageView: UIImageView = {
        let imageView = UIImageView(frame: bounds)
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        insertSubview(imageView, at: 0)
        return imageView
    }()
}
