import MobileCoreServices
import UIKit

extension UIImagePickerController {
    
    typealias CameraDelegate = UIImagePickerControllerDelegate & UINavigationControllerDelegate
    
    static var canRecordVideos: Bool {
        isSourceTypeAvailable(.camera)
            && (availableMediaTypes(for: .camera) ?? []).contains(kUTTypeMovie as String)
            && isCameraDeviceAvailable(.rear) || isCameraDeviceAvailable(.front)
    }
    
    /// A picker configured to record videos if the device can record videos, otherwise `nil`.
    ///
    /// If the preferred camera is not available, falls back to `.rear`.
    static func videoController(
        with preferredCamera: CameraDevice,
        delegate: CameraDelegate? = nil
    ) -> UIImagePickerController? {
        
        guard canRecordVideos else { return nil }
        
        let camera = isCameraDeviceAvailable(preferredCamera) ? preferredCamera : .rear
        let picker = UIImagePickerController()
        
        picker.delegate = delegate
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.sourceType = .camera
        picker.cameraCaptureMode = .video
        picker.cameraDevice = camera
        picker.videoQuality = .typeHigh
        
        return picker
    }
}
