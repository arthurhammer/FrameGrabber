import UIKit
import AVFoundation

extension CGSize {
    /// The receiver scaled with the screen's scale.
    public var scaledToScreen: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: width * scale, height: height * scale)
    }

    /// The receiver divided by the screen's scale.
    public var unscaledFromScreen: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: width / scale, height: height / scale)
    }
}

extension CGSize {
    
    /// The receiver with absolute width and height values.
    public var abs: CGSize {
        CGSize(width: Swift.abs(width), height: Swift.abs(height))
    }
}

extension CGSize {

    /// A rect scaled such that it maintains the receiver's aspect ratio inside another
    /// rect.
    public func aspectFitting(_ boundingRect: CGRect) -> CGRect {
        AVMakeRect(aspectRatio: self, insideRect: boundingRect)
    }

    /// The receiver's aspect ratio scaled such that it is fully enclosed by the given
    /// size.
    public func aspectFitting(_ boundingSize: CGSize) -> CGSize {
        aspectFitting(CGRect(origin: .zero, size: boundingSize)).size
     }

    /// The receiver's aspect ratio scaled such that it minimally fills the given size.
    public func aspectFilling(_ size: CGSize) -> CGSize {
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
