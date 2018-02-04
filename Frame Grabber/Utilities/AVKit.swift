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

    /// - Note: After the method returns, `requestedTimeToleranceAfter`
    /// and `requestedTimeToleranceBefore` will be `kCMTimeZero`.
    func copyCGImage(atExactTime time: CMTime, completion: (Error?, CGImage?) -> ()) {
        requestedTimeToleranceBefore = .zero
        requestedTimeToleranceAfter = .zero

        let image: CGImage?

        do {
            image = try copyCGImage(at: time, actualTime: nil)
        } catch let error {
            completion(error, nil)
            return
        }

        completion(nil, image)
    }
}
