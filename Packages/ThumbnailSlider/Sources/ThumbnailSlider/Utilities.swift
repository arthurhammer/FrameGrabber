import AVFoundation
import CoreMedia
import UIKit

extension AVAsset {
    var dimensions: CGSize? {
        guard let videoTrack = tracks(withMediaType: .video).first else { return nil }
        let rotated = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        return CGSize(width: abs(rotated.width), height: abs(rotated.height))
    }
}

extension CGSize {
    var scaledToScreen: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: width * scale, height: height * scale)
    }
}

extension CGSize {
    func aspectFitting(height targetHeight: CGFloat) -> CGSize? {
        guard height != 0 else { return nil }

        let heightScale = targetHeight / abs(height)

        return CGSize(width: abs(width) * heightScale, height: targetHeight)
    }
}

extension CGRect {
    func increased(to minimumSize: CGSize) -> CGRect {
        var result = self

        result.size = CGSize(
            width: max(size.width, minimumSize.width),
            height: max(size.height, minimumSize.height)
        )

        result.origin = CGPoint(
            x: midX - result.width/2,
            y: midY - result.height/2
        )

        return result
    }
}

extension CMTime {
    var numericOrZero: CMTime {
        isNumeric ? self : .zero
    }
}

extension Comparable {
    func clamped(to lower: Self, and upper: Self) -> Self {
        precondition(lower <= upper, "\(lower) <= \(upper)")
        return max(lower, min(upper, self))
    }
}
