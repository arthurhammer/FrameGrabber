import UIKit
import Photos

class SaveToPhotosAction {
    
    enum Item: Hashable {
        case image(URL)
        case video(URL)
    }
    
    enum Album: Hashable {
        
        /// Albums that do not support adding assets (e.g. smart albums) are skipped silently.
        case existing(PHAssetCollection)
        
        /// The album with the given name, optionally creating it if it doesn't exist. If multiple
        /// albums with the name already exist, it is undefined which one is returned.
        case named(String, createIfNeeded: Bool)
        
        /// The "Frame Grabber" photo album to save exported frames and recorded videos to.
        static let appAlbum = Album.named(Localized.photoLibraryAppAlbum, createIfNeeded: true)
    }
    
    private let photoLibrary: PHPhotoLibrary
    
    init(photoLibrary: PHPhotoLibrary = .shared()) {
        self.photoLibrary = photoLibrary
    }

    /// Saves the items to the photo library and, optionally, to the specified albums.
    ///
    /// The receiver maintains a strong reference to itself until the completion handler is called.
    ///
    /// - Parameters:
    ///   - completion: Is called on the main queue.
    func save(
        _ items: [Item],
        addingToAlbums albums: [Album] = [],
        completion: ((Bool, Error) -> Void)?
    ) {
        photoLibrary.performChanges({
            self.performSave(items: items, addingToAlbums: albums)
        }) { ok, error in
            DispatchQueue.main.async {
                completion?(ok, error)
            }
        }
    }
    
    // The following methods must be called from inside a photo library change block.
    
    private func performSave(items: [Item], addingToAlbums albums: [Album]) {
        let assets = createAssets(for: items)
        
        albums.forEach {
            add(assets, to: $0)
        }
    }
    
    private func createAssets(for items: [Item]) -> [PHObjectPlaceholder] {
        items.compactMap {
            creationRequest(for: $0)?.placeholderForCreatedAsset
        }
    }
    
    private func add(_ assets: [PHObjectPlaceholder], to album: Album) {
        var changeRequest: PHAssetCollectionChangeRequest? = nil
        var canAdd: Bool = true
        
        switch album {

        case let .existing(assetCollection):
            changeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
            canAdd = assetCollection.canPerform(.addContent)

        case let .named(name, createIfNeeded):
            if let assetCollection = fetchAlbum(named: name) {
                changeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
                canAdd = assetCollection.canPerform(.addContent)
            } else if createIfNeeded {
                changeRequest = .creationRequestForAssetCollection(withTitle: name)
            }
        }
        
        if canAdd {
            changeRequest?.addAssets(assets as NSArray)
        }
    }
    
    private func fetchAlbum(named name: String) -> PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "localizedTitle == %@", name)

        return PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: options
        ).firstObject
    }
    
    private func creationRequest(for item: Item) -> PHAssetCreationRequest? {
        switch item {
        case .image(let url):
            return .creationRequestForAssetFromImage(atFileURL: url)
        case .video(let url):
            return .creationRequestForAssetFromVideo(atFileURL: url)
        }
    }
}
