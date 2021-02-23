import AVFoundation
import MobileCoreServices
import UIKit

extension UIImagePickerController {
    
    typealias Delegate = UIImagePickerControllerDelegate & UINavigationControllerDelegate
    
    /// Whether the device is capable of recording videos.
    ///
    /// The authorization status is not considered.
    static var canRecordVideos: Bool {
        isSourceTypeAvailable(.camera)
            && (availableMediaTypes(for: .camera) ?? []).contains(kUTTypeMovie as String)
            && (isCameraDeviceAvailable(.rear) || isCameraDeviceAvailable(.front))
    }
    
    /// Whether the video camera authorization status is denied or restricted.
    static var videoRecordingAuthorizationDenied: Bool {
        [.denied, .restricted].contains(AVCaptureDevice.authorizationStatus(for: .video))
    }
}
