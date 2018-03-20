import AVKit

extension CMTime {
    static let zero = kCMTimeZero
    static let positiveInfinity = kCMTimePositiveInfinity
    static let indefinite = kCMTimeIndefinite

    init(seconds: Double, preferredTimeScale: CMTimeScale = CMTimeScale(NSEC_PER_SEC)) {
        self.init(seconds: seconds, preferredTimescale: preferredTimeScale)
    }
}

extension AVAssetImageGenerator {

    /// Asynchronously generates an image.
    /// - Note: This method changes the receiver's `requestedTimeToleranceAfter` and
    /// `requestedTimeToleranceBefore` properties.
    func generateImage(at time: CMTime,
                       toleranceBefore: CMTime = .zero,
                       toleranceAfter: CMTime = .zero,
                       completionHandler: @escaping AVAssetImageGeneratorCompletionHandler) {

        let times = [NSValue(time: time)]

        requestedTimeToleranceBefore = toleranceBefore
        requestedTimeToleranceAfter = toleranceAfter

        generateCGImagesAsynchronously(forTimes: times, completionHandler: completionHandler)
    }
}
