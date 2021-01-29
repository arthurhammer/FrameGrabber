import PhotoAlbums
import Photos
import UIKit

class Coordinator: NSObject {

    let navigationController: NavigationController
    let libraryViewController: AlbumViewController
    let transitionController: ZoomTransitionController
    
    private(set) lazy var albumPicker = AlbumPickerViewController(dataSource: albumsDataSource)
    
    private(set) lazy var albumsDataSource: AlbumsDataSource = {
        assert(!needsAuthorization, "Photo library access before authorization")
        return AlbumsDataSource.default()
    }()
    
    private var needsAuthorization: Bool {
        AuthorizationController.needsAuthorization
    }

    init(navigationController: NavigationController) {
        guard let albumViewController = navigationController.topViewController as? AlbumViewController else { fatalError("Wrong root controller or type.") }
        
        self.navigationController = navigationController
        self.libraryViewController = albumViewController
        self.transitionController = ZoomTransitionController(navigationController: navigationController)
        
        super.init()
    }
    
    // MARK: - Start

    func start() {
        libraryViewController.delegate = self
        libraryViewController.defaultTitle =  UserText.albumUnauthorizedTitle
        
        showAuthorizationIfNeeded { [weak self] in
            self?.configureLibrary()
        }
    }
    
    func open(videoUrl: URL) -> Bool {
        guard !needsAuthorization else { return false }
        
        dismissAllScreens(animated: true) {
            self.showEditor(for: .url(videoUrl), previewImage: nil)
        }
        
        return true
    }
    
    private func dismissAllScreens(animated: Bool, completion: (() -> ())? = nil) {
        navigationController.dismiss(animated: animated) {
            self.navigationController.popToRootViewController(animated: animated)
            
            DispatchQueue.main.async {
                completion?()
            }
        }
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
    
    private func configureLibrary() {
        assert(!needsAuthorization, "Photo library access before authorization")
        
        libraryViewController.defaultTitle = UserText.albumDefaultTitle
        
        if let initialAlbum = AlbumsDataSource.fetchInitialAssetCollection() {
            libraryViewController.setSourceAlbum(AnyAlbum(assetCollection: initialAlbum))
        }
        
        _ = albumsDataSource  // Preload albums.
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
    
    private func showEditor(for source: VideoSource, previewImage: UIImage?) {
        let storyboard = UIStoryboard(name: "Editor", bundle: nil)
        let videoController = VideoController(source: source, previewImage: previewImage)
        
        guard let editor = storyboard.instantiateInitialViewController(creator: {
            EditorViewController(videoController: videoController, delegate: self, coder: $0)
        }) else { return }
        
        navigationController.show(editor, sender: self)
    }
}

// MARK: - AlbumViewControllerDelegate

extension Coordinator: AlbumViewControllerDelegate {
    
    func controllerDidSelectAlbumPicker(_ controller: AlbumViewController) {
        showAlbumPicker()
    }
    
    func controllerDidSelectFilePicker(_ controller: AlbumViewController) {
        if #available(iOS 14.0, *) {
            showFilePicker()
        }
    }
    
    func controller(_ controller: AlbumViewController, didSelectEditorForAsset asset: PHAsset, previewImage: UIImage?) {
        showEditor(for: .photoLibrary(asset), previewImage: previewImage)
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
    
    func picker(_ picker: AlbumPickerViewController, didFinishPicking album: AnyAlbum?) {
        guard let album = album else { return }
        libraryViewController.setSourceAlbum(album)
    }
}

// MARK: - File Picker

extension Coordinator: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        showEditor(for: .url(url), previewImage: nil)
    }
}
