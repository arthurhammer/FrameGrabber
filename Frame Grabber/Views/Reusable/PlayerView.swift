import UIKit
import AVKit

class PlayerView: UIView {

    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    var player: AVPlayer? {
        get { return playerLayer.player }
        // TODO: dont set everytime to avoid flickering!!!!!!!!!! (every time on status == ready when looping)
        set {
            print("TODO: DONT SET PLAYER ON EVERY LOOP!")
            playerLayer.player = newValue

        }
    }
}
