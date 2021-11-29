import CoreMedia
import UIKit

public protocol ThumbnailSliderDataSource: AnyObject {

    /// The aspect ratio for the slider's thumbnails.
    ///
    /// The slider calculates the number of thumbnails, image sizes and time offsets from this
    /// value.
    func thumbnailAspectRatio(in slider: ThumbnailSlider) -> CGSize

    /// Asynchronously provides thumbnails for the given video times.
    ///
    /// - Parameters:
    ///   - size: The requested thumbnail size. The size of provided images may differ.
    ///   - provider: Must be called on the main queue. Can be called multiple times for a given
    ///     index, e.g. to provide an initial placeholder followed with the actual thumbnail. The
    ///     slider always requests all thumbnails in a single invocation of this function. Previous
    ///     pending thumbnail providers may be discarded.
    func slider(
        _ slider: ThumbnailSlider,
        loadThumbnailsForTimes times: [CMTime],
        size: CGSize,
        provider: @escaping (Int, UIImage?) -> ()
    )
}
