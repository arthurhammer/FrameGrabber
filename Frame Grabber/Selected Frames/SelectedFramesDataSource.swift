import AVFoundation
import UIKit

/// Data source for frame selections. Frames are kept unique and sorted by time.
class SelectedFramesDataSource {

    struct Frame {
        /// The time for which an image was requested.
        let requestedTime: CMTime
        /// The time at which an image was generated, i.e. the time of the nearest frame
        /// to the requested time. Is nil in case frame generation fails or is cancelled.
        let actualTime: CMTime?
        let image: UIImage?
    }

    enum InsertionResult {
        case inserted(Int, Frame)
        case existing(Int, Frame)
    }

    let video: AVAsset
    private(set) var frames = [Frame]()
    private(set) var isGeneratingFrames = false

    /// Changing the size does not affect already generated frames.
    var imageSize: CGSize = .zero {
        didSet {
            guard let dimensions = video.dimensions else { return }
            frameGenerator.maximumSize = dimensions.aspectFilling(imageSize)
        }
    }

    private lazy var frameGenerator: AVAssetImageGenerator = .default(for: video)

    init(video: AVAsset) {
        self.video = video
    }

    deinit {
        frameGenerator.cancelAllCGImageGeneration()
    }

    /// Stored frames are kept sorted and unique based on their actual time. Multiple
    /// requested frame times can map to a single actual frame time. Thus, to determine
    /// whether a frame for a requested time can be inserted, the frame and its actual
    /// time need to be generated first. The completion handler is called with the newly
    /// inserted frame or an existing one for the requested time.
    func generateAndInsertFrame(for requestedTime: CMTime, completion: @escaping (InsertionResult) -> ()) {
        generateFrame(for: requestedTime) { [weak self] frame in
            guard let self = self else { return }
            completion(self.insert(frame))
        }
    }

    func insert(_ frame: Frame) -> InsertionResult {
        if let index = frames.firstIndex(of: frame) {
            return .existing(index, frames[index])
        }

        let index = insertionIndex(for: frame)
        frames.insert(frame, at: index)
        return .inserted(index, frame)
    }

    func removeFrame(at index: Int) {
        frames.remove(at: index)
    }

    private func insertionIndex(for frame: Frame) -> Int {
        frames.firstIndex { $0.definingTime >= frame.definingTime } ?? frames.count
    }

    func generateFrame(for time: CMTime, completion: @escaping (Frame) -> ()) {
        isGeneratingFrames = true

        let time = NSValue(time: time)

        frameGenerator.generateCGImagesAsynchronously(forTimes: [time]) { [weak self] requestedTime, cgImage, actualTime, result, _ in
            DispatchQueue.main.async {
                self?.isGeneratingFrames = false

                // Even if generation fails or cancels, the result is still a valid frame.
                let frame = Frame(requestedTime: requestedTime,
                                  actualTime: (result == .succeeded) ? actualTime : nil,
                                  image: cgImage.flatMap(UIImage.init))
                completion(frame)
            }
        }
    }
}

extension SelectedFramesDataSource.Frame: Equatable {

    /// `actualTime` if it could be determined, otherwise `requestedTime`.
    /// - Note: Equality for this type is solely defined by this property.
    var definingTime: CMTime {
        actualTime ?? requestedTime
    }

    static func ==(lhs: SelectedFramesDataSource.Frame, rhs: SelectedFramesDataSource.Frame) -> Bool {
        lhs.definingTime == rhs.definingTime
    }
}

extension SelectedFramesDataSource.InsertionResult {

    var index: Int {
        switch self {
        case .existing(let index, _): return index
        case .inserted(let index, _): return index
        }
    }

    var frame: SelectedFramesDataSource.Frame {
        switch self {
        case .existing(_, let frame): return frame
        case .inserted(_, let frame): return frame
        }
    }
}
