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
}

class PreviewPlayerView: PlayerView {

    let posterImageView = UIImageView(frame: .zero)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureViews()
    }

    private func configureViews() {
        posterImageView.frame = bounds
        posterImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        addSubview(posterImageView)
    }
}
