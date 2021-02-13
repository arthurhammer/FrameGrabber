import PhotoAlbums
import Photos
import UIKit

class Coordinator: NSObject {

    let navigationController: UINavigationController
    let libraryViewController: LibraryViewController
    let transitionController: ZoomTransitionController
    let fileManager = FileManager.default
    let settings = UserDefaults.standard
    
    private(set) lazy var albumPicker = AlbumPickerViewController(dataSource: albumsDataSource)
    
    private(set) lazy var albumsDataSource: AlbumsDataSource = {
        assert(!needsAuthorization, "Photo library access before authorization")
        return AlbumsDataSource.makeDefaultDataSource()
    }()
    
    private var needsAuthorization: Bool {
        AuthorizationController.needsAuthorization
    }

    init(navigationController: UINavigationController) {
        guard let albumViewController = navigationController.topViewController as? LibraryViewController else { fatalError("Wrong root controller or type.") }
        
        self.navigationController = navigationController
        self.libraryViewController = albumViewController
        self.transitionController = ZoomTransitionController(navigationController: navigationController)
        
        super.init()
    }
    
    // MARK: - Start

    func start() {
        libraryViewController.delegate = self
        
        showAuthorizationIfNeeded { [weak self] in
            self?.showRecentsAlbum()
            self?.preloadAlbums()
        }
    }
    
    func open(videoUrl: URL) -> Bool {
        guard !needsAuthorization else { return false }

        showEditor(with: .url(videoUrl), previewImage: nil, animated: true)
        navigationController.dismiss(animated: true)

        return true
    }

    // MARK: Screens

    private func showAuthorizationIfNeeded(completion: @escaping () -> ()) {
        if needsAuthorization {
            DispatchQueue.main.async {
                self.showAuthorization(animated: true, completion: completion)
            }
        } else {
            completion()
        }
    }

    private func showAuthorization(animated: Bool, completion: @escaping () -> ()) {
        let authorizationController = ViewControllerFactory.makeAuthorization { [weak self] in
            self?.navigationController.dismiss(animated: true)
            completion()
        }
        
        navigationController.present(authorizationController, animated: animated)
    }
    
    private func showRecentsAlbum() {
        assert(!needsAuthorization, "Photo library access before authorization")

        if let recents = AlbumsDataSource.fetchFirstAlbum() {
            libraryViewController.dataSource.album = recents
        }
    }
    
    private func preloadAlbums() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            _ = self.albumsDataSource
        }
    }
    
    private func showEditor(with source: VideoSource, previewImage: UIImage?, animated: Bool) {
        libraryViewController.zoomTransitionAsset = source.photoLibraryAsset
        
        let editor = ViewControllerFactory.makeEditor(
            with: source,
            previewImage: previewImage,
            delegate: self
        )
        // Let nav controller decide which animation to show. Also supports the correct "open in"
        // animation.
        navigationController.setViewControllers([libraryViewController, editor], animated: animated)
    }
    
    private func showAlbumPicker() {
        assert(!needsAuthorization, "Photo library access before authorization")
        albumPicker.delegate = self
        navigationController.showDetailViewController(albumPicker, sender: self)
    }
    
    private func showFilePicker() {
        let picker = ViewControllerFactory.makeFilePicker(withDelegate: self)
        navigationController.showDetailViewController(picker, sender: self)
    }
    
    private func showCamera() {
        guard let camera = ViewControllerFactory.makeCamera(with: settings.camera, delegate: self) else {
            navigationController.presentAlert(.videoRecordingUnavailable())
            return
        }
        
        guard !UIImagePickerController.videoRecordingAuthorizationDenied else {
            navigationController.presentAlert(.videoRecordingDenied())
            return
        }
        
        navigationController.present(camera, animated: true)
    }
}

// MARK: - LibraryViewControllerDelegate

extension Coordinator: LibraryViewController.Delegate {
    
    func controllerDidSelectAlbumPicker(_ controller: LibraryViewController) {
        showAlbumPicker()
    }
    
    func controllerDidSelectFilePicker(_ controller: LibraryViewController) {
        showFilePicker()
    }
    
    func controllerDidSelectCamera(_ controller: LibraryViewController) {
        showCamera()
    }

    func controller(_ controller: LibraryGridViewController, didSelectAsset asset: PHAsset, previewImage: UIImage?) {
        showEditor(with: .photoLibrary(asset), previewImage: previewImage, animated: true)
    }
}

// MARK: - EditorViewControllerDelegate

extension Coordinator: EditorViewControllerDelegate {
    
    func controller(_ controller: EditorViewController, handleSlideToPopGesture gesture: UIPanGestureRecognizer) {
        transitionController.handleSlideToPopGesture(gesture)
    }
}

// MARK: - AlbumPickerViewControllerDelegate

extension Coordinator: AlbumPickerViewControllerDelegate {
    
    func picker(_ picker: AlbumPickerViewController, didFinishPicking album: PhotoAlbum?) {
        guard let album = album else { return }
        libraryViewController.dataSource.album = album.assetCollection
    }
}

// MARK: - File Picker

extension Coordinator: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first,
              let newURL = try? fileManager.importFile(at: url, asCopy: true, deletingSource: true)
        else {
            navigationController.presentAlert(.filePickingFailed())
            return
        }
        
        showEditor(with: .url(newURL), previewImage: nil, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension Coordinator: UIImagePickerController.Delegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        settings.camera = picker.cameraDevice
        navigationController.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        settings.camera = picker.cameraDevice
        
        guard let url = info[.mediaURL] as? URL else {
            navigationController.presentAlert(.recordingVideoFailed())
            return
        }
        
        showEditor(with: .camera(url), previewImage: nil, animated: false)

        navigationController.dismiss(animated: true)  {
            self.saveVideoToPhotoLibrary(url)
        }
    }
    
    private func saveVideoToPhotoLibrary(_ url: URL) {
        let currentAlbum = libraryViewController.dataSource.album

        SaveToPhotosAction().save(
            [.video(url)],
            addingToAlbums: [
                .appAlbum,
                currentAlbum.flatMap { .existing($0) }
            ].compactMap { $0 },
            completion: nil
        )
    }
}
