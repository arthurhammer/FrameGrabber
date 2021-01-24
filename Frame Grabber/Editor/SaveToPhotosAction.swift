import UIKit
import Photos

class SaveToPhotosAction {
        
    /// Creates and performs the save to Photos action.
    ///
    /// The action is immediately performed in the initializer, retaining the instance until the
    /// action is completed.
    ///
    /// - Parameters:
    ///   - completionHandler: Is called on the main queue.
    @discardableResult
    init(
        imageUrls: [URL],
        photoAlbum: String? = nil,
        photoLibrary: PHPhotoLibrary = .shared(),
        completionHandler: ((Bool, Error) -> ())?
    ) {
        photoLibrary.performChanges({
            self.saveImages(for: imageUrls, addingToAlbum: photoAlbum)
        }) { ok, error in
            DispatchQueue.main.async {
                completionHandler?(ok, error)
            }
        }
    }

    // The following methods must be called from inside a photo library change block.
    
    private func saveImages(for urls: [URL], addingToAlbum album: String?) {
        let assets = createAssets(for: urls)
        
        if let album = album {
            add(assets, to: album, createIfNeeded: true)
        }
    }
    
    private func createAssets(for urls: [URL]) -> [PHObjectPlaceholder] {
        urls.compactMap {
            PHAssetCreationRequest
                .creationRequestForAssetFromImage(atFileURL: $0)?
                .placeholderForCreatedAsset
        }
    }
    
    private func add(_ assets: [PHObjectPlaceholder], to album: String, createIfNeeded: Bool) {
        var request: PHAssetCollectionChangeRequest? = nil
        
        if let album = fetchAlbum(with: album) {
           request = PHAssetCollectionChangeRequest(for: album)
        } else if createIfNeeded {
            request = PHAssetCollectionChangeRequest
                .creationRequestForAssetCollection(withTitle: album)
        }
        
        request?.addAssets(assets as NSArray)
    }
    
    private func fetchAlbum(with name: String) -> PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "localizedTitle == %@", name)

        return PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: options
        ).firstObject
    }
}
