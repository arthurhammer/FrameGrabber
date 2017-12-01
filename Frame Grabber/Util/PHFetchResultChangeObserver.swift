import Photos

/// Observes and reports changes to a single `PHFetchResult`.
class PHFetchResultChangeObserver<T>: NSObject, PHPhotoLibraryChangeObserver where T: PHObject {

    typealias ChangeHandler = (PHChange, PHFetchResultChangeDetails<T>) -> ()
    var changeHandler: ChangeHandler = { _, _ in }
    private(set) var fetchResult: PHFetchResult<T>

    init(fetchResult: PHFetchResult<T>) {
        self.fetchResult = fetchResult
        super.init()
        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    func photoLibraryDidChange(_ change: PHChange) {
        guard let details = change.changeDetails(for: fetchResult) else { return }

        DispatchQueue.main.async {
            self.fetchResult = details.fetchResultAfterChanges
            self.changeHandler(change, details)
        }
    }
}
