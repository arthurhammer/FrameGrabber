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
            let duration = newValue.validOrZero.seconds
            minimumValue = 0
            maximumValue = Float(duration)
        }
    }

    /// Set `value` interpreted as `CMTime`.
    func setTime(_ time: CMTime, animated: Bool) {
        let time = time.validOrZero.seconds
        setValue(Float(time), animated: animated)
    }
}
