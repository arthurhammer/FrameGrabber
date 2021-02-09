import PhotoAlbums
import Photos
import UIKit

class Coordinator: NSObject {

    let navigationController: UINavigationController
    let libraryViewController: LibraryViewController
    let transitionController: ZoomTransitionController
    let fileManager = FileManager.default
    
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
            _ = self?.albumsDataSource  // Preload albums.
        }
    }
    
    func open(videoUrl: URL) -> Bool {
        guard !needsAuthorization else { return false }

        navigationController.dismiss(animated: true)  // Animated.
        showEditor(with: .url(videoUrl), previewImage: nil, animated: false)  // Not animated.

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
        let storyboard = UIStoryboard(name: "Authorization", bundle: nil)

        guard let authorizationController = storyboard.instantiateInitialViewController() as? AuthorizationController else { fatalError("Wrong controller type") }

        authorizationController.didAuthorizeHandler = { [weak self] in
            self?.navigationController.dismiss(animated: true)
            completion()
        }
        
        authorizationController.modalPresentationStyle = .formSheet
        authorizationController.isModalInPresentation = true
        navigationController.present(authorizationController, animated: animated)
    }
    
    private func showRecentsAlbum() {
        assert(!needsAuthorization, "Photo library access before authorization")

        if let recents = AlbumsDataSource.fetchFirstAlbum() {
            libraryViewController.setAlbum(recents)
        }
    }
    
    private func showEditor(with source: VideoSource, previewImage: UIImage?, animated: Bool) {
        libraryViewController.transitionAsset = source.photoLibraryAsset
        let editor = makeEditor(with: source, previewImage: previewImage)
        
        // Let nav controller decide which animation to show. Also supports the correct "open in"
        // animation.
        navigationController.setViewControllers([libraryViewController, editor], animated: animated)
    }
    
    private func showAlbumPicker() {
        assert(!needsAuthorization, "Photo library access before authorization")
        
        albumPicker.delegate = self
        navigationController.showDetailViewController(albumPicker, sender: self)
    }
    
    @available(iOS 14.0, *)
    private func showFilePicker() {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.movie],
            asCopy: true
        )
        picker.shouldShowFileExtensions = true
        picker.delegate = self
    
        navigationController.showDetailViewController(picker, sender: self)
    }
    
    // MARK: - Controller Factories
    
    private func makeEditor(with source: VideoSource, previewImage: UIImage?) -> EditorViewController {
        let storyboard = UIStoryboard(name: "Editor", bundle: nil)
        let videoController = VideoController(source: source, previewImage: previewImage)
        
        guard let controller = storyboard.instantiateInitialViewController(creator: {
            EditorViewController(videoController: videoController, delegate: self, coder: $0)
        }) else { fatalError("Could not instantiate controller.") }
        
        return controller
    }
}

// MARK: - AlbumViewControllerDelegate

extension Coordinator: AlbumViewControllerDelegate {
    
    func controllerDidSelectAlbumPicker(_ controller: LibraryViewController) {
        showAlbumPicker()
    }
    
    func controllerDidSelectFilePicker(_ controller: LibraryViewController) {
        if #available(iOS 14.0, *) {
            showFilePicker()
        }
    }

    func controller(_ controller: LibraryViewController, didSelectEditorForAsset asset: PHAsset, previewImage: UIImage?) {
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
        libraryViewController.setAlbum(album.assetCollection)
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
