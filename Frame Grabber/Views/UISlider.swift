import UIKit
import AVFoundation

extension UISlider {

    /// `value` interpreted as `CMTime`.
    /// - Note: Times are returned with a time scale of `NSEC_PER_SEC`, even if a time
    ///   with a different scale was set.
    var time: CMTime {
        get { CMTime(seconds: Double(value), preferredTimescale: CMTimeScale(NSEC_PER_SEC)) }
        set { setTime(newValue, animated: false) }
    }

    /// `maximumValue` interpreted as `CMTime`. When setting, sets `minimumValue` to 0.
    /// - Note: Times are returned with a time scale of `NSEC_PER_SEC`, even if a time
    ///   with a different scale was set.
    var duration: CMTime {
        get { CMTime(seconds: Double(maximumValue), preferredTimescale: CMTimeScale(NSEC_PER_SEC)) }
        set {
            let duration = newValue.validOrZero.seconds
            minimumValue = 0
            maximumValue = Float(duration)
        }
    }

    /// Set `value` interpreted as `CMTime`.
    func setTime(_ time: CMTime, animated: Bool) {
        guard !isTracking else { return }
        let time = time.validOrZero.seconds
        setValue(Float(time), animated: animated)
    }
}
