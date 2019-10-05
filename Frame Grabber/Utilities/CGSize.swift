import UIKit
import AVFoundation

extension CGSize {
    /// The receiver scaled with the screen's scale.
    var scaledToScreen: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: width * scale, height: height * scale)
    }
}

extension CGSize {

    func aspectFitting(_ boundingSize: CGSize) -> CGSize {
         let rect = CGRect(origin: .zero, size: boundingSize)
         return AVMakeRect(aspectRatio: self, insideRect: rect).size
     }

    /// The receiver's aspect ratio scaled such that it minimally fills the given size.
    func aspectFilling(_ size: CGSize) -> CGSize {
        guard self != .zero else { return .zero }

        let aspectRatio = width / height

        if width > height {
            return CGSize(width: ceil(size.height * aspectRatio),
                          height: ceil(size.height))
        } else {
            return CGSize(width: ceil(size.width),
                          height: ceil(size.height / aspectRatio))
        }
    }
}
