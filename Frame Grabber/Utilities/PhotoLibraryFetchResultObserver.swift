import Photos

/// Observes and reports changes to a single `PHFetchResult`.
class PhotoLibraryFetchResultObserver<T>: NSObject, PHPhotoLibraryChangeObserver where T: PHObject {

    typealias ChangeHandler = (PHChange, PHFetchResultChangeDetails<T>) -> ()

    var changeHandler: ChangeHandler?
    let library: PHPhotoLibrary
    private(set) var fetchResult: PHFetchResult<T>

    init(library: PHPhotoLibrary = .shared(), fetchResult: PHFetchResult<T>) {
        self.library = library
        self.fetchResult = fetchResult

        super.init()

        library.register(self)
    }

    deinit {
        library.unregisterChangeObserver(self)
    }

    func photoLibraryDidChange(_ change: PHChange) {
        guard let details = change.changeDetails(for: fetchResult) else { return }

        DispatchQueue.main.async {
            self.fetchResult = details.fetchResultAfterChanges
            self.changeHandler?(change, details)
        }
    }
}
