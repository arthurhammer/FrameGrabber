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

    enum Status {
        case cancelled
        case failed(Error?)
        case succeeded(UIImage, requestedTime: CMTime, actualTime: CMTime)
    }

    /// Asynchronously generates an image.
    /// - Note: This method changes the receiver's `requestedTimeToleranceBefore`,
    /// `requestedTimeToleranceAfter` and `appliesPreferredTrackTransform` properties.
    func generateImage(at time: CMTime,
                       toleranceBefore: CMTime = .zero,
                       toleranceAfter: CMTime = .zero,
                       applyingPreferredTrackTransform: Bool = true,
                       completionHandler: @escaping (Status) -> ()) {

        requestedTimeToleranceBefore = toleranceBefore
        requestedTimeToleranceAfter = toleranceAfter
        appliesPreferredTrackTransform = applyingPreferredTrackTransform

        generateCGImagesAsynchronously(forTimes: [time], completionHandler: completionHandler)
    }

    func generateCGImagesAsynchronously(forTimes times: [CMTime], completionHandler: @escaping (Status) -> ()) {
        let times = times.map(NSValue.init)

        generateCGImagesAsynchronously(forTimes: times) { requestedTime, image, actualTime, status, error in
            switch (status, image, error) {

            case (.cancelled, _, _):
                completionHandler(.cancelled)
            case (.succeeded, let image?, _):
                completionHandler(.succeeded(UIImage(cgImage: image), requestedTime: requestedTime, actualTime: actualTime))
            // All other states, e.g. status is `succeeded` but image is `nil`.
            case (_, _, let error):
                completionHandler(.failed(error))
            }
        }
    }
}
