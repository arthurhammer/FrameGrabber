import AVFoundation
import UIKit

public final class AVAssetThumbnailSliderDataSource: ThumbnailSliderDataSource {

    var slider: ThumbnailSlider? {
        didSet {
            oldValue?.dataSource = nil
            slider?.dataSource = self
        }
    }

    public var asset: AVAsset? {
        get { imageGenerator?.asset }
        set {
            guard newValue != asset else { return }
            imageGenerator?.cancelAllCGImageGeneration()
            imageGenerator = makeImageGenerator(for: newValue)
            slider?.reloadThumbnails()
        }
    }

    /// Used while actual images are being generated and for images where generation failed.
    ///
    /// For best results, the aspect ratio of `placeholderImage` and `asset` should match (not
    /// required).
    public var placeholderImage: UIImage?

    private var imageGenerator: AVAssetImageGenerator?
    private let timeTolerance: CMTime
    private let scaleFactor: CGFloat = 2
    
    // Use a fixed 4:3 ratio instead of the video's aspect ratio. Most videos are 16:9 which is a
    // bit too narrow for the thumbnails.
    private let landscapeAspectRatio = CGSize(width: 4, height: 3)

    public init(
        slider: ThumbnailSlider?,
        asset: AVAsset?,
        placeholderImage: UIImage? = nil,
        timeTolerance: CMTime = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    ) {
        self.slider = slider
        self.timeTolerance = timeTolerance
        self.placeholderImage = placeholderImage
        self.imageGenerator = makeImageGenerator(for: asset)
        self.slider?.dataSource = self
    }

    deinit {
        imageGenerator?.cancelAllCGImageGeneration()
    }

    public func thumbnailAspectRatio(in slider: ThumbnailSlider) -> CGSize {
        guard let videoSize = (asset?.dimensions ?? placeholderImage?.size) else {
            return landscapeAspectRatio
        }
              
        return (videoSize.width > videoSize.height)
            ? landscapeAspectRatio
            : CGSize(width: landscapeAspectRatio.height, height: landscapeAspectRatio.width)
    }

    public func slider(
        _ slider: ThumbnailSlider,
        loadThumbnailsForTimes times: [CMTime],
        size: CGSize,
        provider: @escaping (Int, UIImage?) -> ()
    ) {

        imageGenerator?.cancelAllCGImageGeneration()

        if let placeholder = placeholderImage {
            times.enumerated().forEach {
                provider($0.offset, placeholder)
            }
        }

        let times = times.map(NSValue.init)
        var index = -1

        // Add some tolerance so we don't fall under `size`.
        imageGenerator?.maximumSize = size.applying(.init(scaleX: scaleFactor, y: scaleFactor))

        imageGenerator?.generateCGImagesAsynchronously(forTimes: times) {
            [weak self] (requested, image, actual, status, error) in

            DispatchQueue.main.async {
                index += 1

                let image = image.flatMap(UIImage.init) ?? self?.placeholderImage
                self?.placeholderImage = self?.placeholderImage ?? image  // Cache first image.

                guard status != .cancelled else { return }

                provider(index, image)
            }
        }
    }

    private func makeImageGenerator(for asset: AVAsset?) -> AVAssetImageGenerator? {
        guard let asset = asset else { return nil }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceBefore = timeTolerance
        generator.requestedTimeToleranceAfter = timeTolerance
        generator.appliesPreferredTrackTransform = true
        return generator
    }
}
