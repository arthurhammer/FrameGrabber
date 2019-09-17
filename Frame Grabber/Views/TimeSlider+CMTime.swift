import AVKit

extension TimeSlider {
    /// `value` interpreted as `CMTime`.
    var time: CMTime {
        get { CMTime(seconds: Double(value)) }
        set { setTime(newValue, animated: false) }
    }

    /// `maximumValue` interpreted as `CMTime`. When setting, sets `minimumValue` to 0.
    var duration: CMTime {
        get { CMTime(seconds: Double(maximumValue)) }
        set {
            minimumValue = 0
            maximumValue = Float(newValue.seconds)
        }
    }

    /// Set `value` interpreted as `CMTime`.
    func setTime(_ time: CMTime, animated: Bool) {
        setValue(Float(time.seconds), animated: animated)
    }
}
