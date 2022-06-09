import AVFoundation
import MobileCoreServices
import UIKit

extension UIImagePickerController {
    
    public typealias Delegate = UIImagePickerControllerDelegate & UINavigationControllerDelegate
    
    /// Whether the device is capable of recording videos.
    ///
    /// The authorization status is not considered.
    public static var canRecordVideos: Bool {
        isSourceTypeAvailable(.camera)
            && (availableMediaTypes(for: .camera) ?? []).contains(UTType.movie.identifier)
            && (isCameraDeviceAvailable(.rear) || isCameraDeviceAvailable(.front))
    }
    
    /// Whether the video camera authorization status is denied or restricted.
    public static var videoRecordingAuthorizationDenied: Bool {
        [.denied, .restricted].contains(AVCaptureDevice.authorizationStatus(for: .video))
    }
}
