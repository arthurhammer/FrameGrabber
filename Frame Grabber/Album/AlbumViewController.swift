import PhotoAlbums
import Photos
import PhotosUI
import UIKit

class AlbumViewController: UICollectionViewController {
        
    /// The title that will be used when album is `nil`.
    var defaultTitle = UserText.albumDefaultTitle {
        didSet { updateViews() }
    }
    
    override var title: String? {
        didSet {
            navigationItem.title = nil
            titleButton.setTitle(title, for: .normal, animated: false)
        }
    }

    /// The most recently selected asset.
    private(set) var selectedAsset: PHAsset?

    @IBOutlet private var titleButton: UIButton!
    @IBOutlet private var viewSettingsButton: AlbumViewSettingsButton!

    private lazy var emptyView = EmptyAlbumView()
    private lazy var durationFormatter = VideoDurationFormatter()
    
    private lazy var dataSource: AlbumCollectionViewDataSource = AlbumCollectionViewDataSource {
        [unowned self] in
        self.cell(for: $1, at: $0)
    }

    private lazy var albumsContainerController: UIViewController = {
        guard let albumsNavController = UIStoryboard(name: "Albums", bundle: nil).instantiateInitialViewController() as? UINavigationController,
              let albumsPicker = albumsNavController.topViewController as? AlbumsViewController else { fatalError("Wrong controller type") }
            
        albumsPicker.delegate = self
        return albumsNavController
    }()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureDataSource()
        configureViews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateNavigationBar()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateContentInsetForViewSettingsButton()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? UINavigationController,
           let controller = destination.topViewController as? AlbumsViewController {
            prepareForAlbumsSegue(with: controller)
        } else if let destination = segue.destination as? EditorViewController {
            prepareForPlayerSegue(with: destination)
        }
    }
    
    private func prepareForAlbumsSegue(with destination: AlbumsViewController) {
        destination.delegate = self
    }

    private func prepareForPlayerSegue(with destination: EditorViewController) {
        guard let selectedIndexPath = collectionView?.indexPathsForSelectedItems?.first else { fatalError("Segue without selection or asset") }

        // (todo: Handle this in coordinator/delegate/navigation controller.)
        let transitionController = ZoomTransitionController()
        navigationController?.delegate = transitionController
        destination.transitionController = transitionController

        let selectedAsset = dataSource.video(at: selectedIndexPath)
        self.selectedAsset = selectedAsset
        let thumbnail = videoCell(at: selectedIndexPath)?.imageView.image
        destination.videoController = VideoController(asset: selectedAsset, previewImage: thumbnail)
    }
    
    // MARK: - Setting Albums
    
    /// Sets the current photo album.
    ///
    /// - Note: Upon first call, the receiver will start accessing the user's photo library. If
    ///         the authorization is `notDetermined`, this will trigger an authorization dialog.
    func setSourceAlbum(_ sourceAlbum: AnyAlbum) {
        dataSource.startAccessingPhotoLibrary()
        dataSource.setSourceAlbum(sourceAlbum)
    }

    // MARK: - Actions

    /// Selects `selectedAsset` in the collection view.
    func restoreSelection(animated: Bool) {
        let selectedIndexPath = selectedAsset.flatMap { dataSource.indexPath(of: $0) }
        collectionView.selectItem(at: selectedIndexPath, animated: animated, scrollPosition: [])
    }
    
    @objc private func showAlbumsPicker() {
        present(albumsContainerController, animated: true)
    }

    // MARK: - Collection View Data Source & Delegate

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? VideoCell else { return }
        
        setGridContentMode(dataSource.gridContentMode, for: cell, at: indexPath, animated: false)
    }

    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? VideoCell)?.imageRequest = nil
    }

    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let video = dataSource.video(at: indexPath)
        let thumbnail = videoCell(at: indexPath)?.imageView.image

        return VideoCellContextMenu.menuConfiguration(
            for: video,
            at: indexPath,
            initialPreviewImage: thumbnail
        ) { [weak self] selection in

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.handleCellContextMenuSelection(selection, for: video)
            }
        }
    }
    
    private func handleCellContextMenuSelection(_ selection: VideoCellContextMenu.Selection, for video: PHAsset) {
        switch selection {
        
        case .favorite:
            dataSource.toggleFavorite(for: video)
            
        case .delete:
            dataSource.delete(video)
        }
    }

    override func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = videoCell(at: indexPath) else { return nil }

        return UITargetedPreview(view: cell.imageContainer)
    }

    override func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        self.collectionView(collectionView, previewForHighlightingContextMenuWithConfiguration: configuration)
    }

    override func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let indexPath = configuration.identifier as? IndexPath else { return }

        animator.addAnimations {
            self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            self.performSegue(withIdentifier: EditorViewController.className, sender: nil)
        }
    }
}

// MARK: - AlbumsViewControllerDelegate

extension AlbumViewController: AlbumsViewControllerDelegate {
    
    func controller(_ controller: AlbumsViewController, didSelectAlbum album: AnyAlbum) {
        dataSource.setSourceAlbum(album)
    }
}

private extension AlbumViewController {
    
    // MARK: Configuring

    func configureViews() {
        collectionView.collectionViewLayout = AlbumGridLayout { [weak self] newItemSize in
            self?.dataSource.imageOptions.size = newItemSize.scaledToScreen
        }
        
        collectionView.isPrefetchingEnabled = true
        collectionView.dataSource = dataSource
        collectionView.prefetchDataSource = dataSource
        collectionView.backgroundView = emptyView
        collectionView.collectionViewLayout.invalidateLayout()

        titleButton.configureDynamicTypeLabel()
        titleButton.configureTrailingAlignedImage()
        
        if #available(iOS 14, *) {
            viewSettingsButton.showsMenuAsPrimaryAction = true
        } else {
            let action = #selector(showViewSettingsAlertSheet)
            viewSettingsButton.addTarget(self, action: action, for: .touchUpInside)
        }
        
        viewSettingsButton.add(to: view)
        updateViews()
    }

    func updateViews() {
        guard isViewLoaded else { return }
        
        if #available(iOS 14.0, *),
           dataSource.isAuthorizationLimited {

            title = UserText.albumLimitedAuthorizationTitle
            titleButton.showsMenuAsPrimaryAction = true
            
            titleButton.menu = LimitedAuthorizationMenu.menu { [weak self] selection in
                self?.handleLimitedAuthorizationMenuSelection(selection)
            }
        } else {
            title = dataSource.album?.title ?? defaultTitle
            titleButton.addTarget(self, action: #selector(showAlbumsPicker), for: .touchUpInside)
        }

        emptyView.type = dataSource.filter
        emptyView.isEmpty = dataSource.isEmpty

        updateViewSettingsButton()
        updateNavigationBar()
    }
    
    func updateNavigationBar() {
        navigationController?.navigationBar.shadowImage = nil
        navigationController?.navigationBar.layer.shadowOpacity = 0

        if #available(iOS 14.0, *) {
            navigationItem.backButtonDisplayMode = .minimal
        }
    }
        
    func configureDataSource() {
        dataSource.albumChangedHandler = { [weak self] _ in
            self?.updateViews()
        }

        dataSource.videosChangedHandler = { [weak self] changeDetails in
            self?.updateViews()

            guard let changeDetails = changeDetails else {
                self?.collectionView?.reloadData()
                return
            }

            self?.collectionView?.applyPhotoLibraryChanges(for: changeDetails, cellConfigurator: {
                self?.reconfigure(cellAt: $0)
            })
        }
    }
    
    @available(iOS 14, *)
    func handleLimitedAuthorizationMenuSelection(_ selection: LimitedAuthorizationMenu.Selection) {
        switch selection {
        
        case .selectPhotos:
            dataSource.photoLibrary.presentLimitedLibraryPicker(from: self)
            
        case .openSettings:
            UIApplication.shared.openSettings()
        }
    }

    // MARK: View Settings Button

    func updateViewSettingsButton() {
        viewSettingsButton.setTitle(dataSource.filter.title, for: .normal, animated: false)
        
        if #available(iOS 14, *) {
            viewSettingsButton.menu = AlbumViewSettingsMenu.menu(
                forCurrentFilter: dataSource.filter,
                gridMode: dataSource.gridContentMode,
                handler: { [weak self] selection in
                    DispatchQueue.main.async {
                        self?.handleViewSettingsMenuSelection(selection)
                    }
                }
            )
        }
    }

    @objc func showViewSettingsAlertSheet() {
        let controller = AlbumViewSettingsMenu.alertController(
            forCurrentFilter: dataSource.filter,
            gridMode: dataSource.gridContentMode,
            handler: { [weak self] selection in
                DispatchQueue.main.async {
                    self?.handleViewSettingsMenuSelection(selection)
                }
            }
        )

        presentAlert(controller)
    }

    func handleViewSettingsMenuSelection(_ selection: AlbumViewSettingsMenu.Selection) {
        UISelectionFeedbackGenerator().selectionChanged()

        switch selection {
        
        case .videosFilter(let filter):
            dataSource.filter = filter
            
        case .gridMode(let mode):
            dataSource.gridContentMode = mode
            setGridContentModeForVisibleCells(mode, animated: true)
        }

        updateViewSettingsButton()
    }

    func updateContentInsetForViewSettingsButton() {
        let topMargin: CGFloat = 8
        let bottomInset = viewSettingsButton.bounds.height + topMargin

        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
        collectionView.verticalScrollIndicatorInsets = collectionView.contentInset
    }

    // MARK: Cell Handling
    
    func videoCell(at indexPath: IndexPath) -> VideoCell? {
        collectionView.cellForItem(at: indexPath) as? VideoCell
    }

    func cell(for video: PHAsset, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: VideoCell.className, for: indexPath) as? VideoCell else { fatalError("Wrong cell identifier or type.") }
        
        configure(cell: cell, for: video)
        return cell
    }

    func configure(cell: VideoCell, for video: PHAsset) {
        cell.durationLabel.text = durationFormatter.string(from: video.duration)
        cell.durationLabel.isHidden = video.isLivePhoto
        cell.livePhotoImageView.isHidden = !video.isLivePhoto
        cell.favoritedImageView.isHidden = !video.isFavorite

        loadThumbnail(for: cell, video: video)
    }

    func reconfigure(cellAt indexPath: IndexPath) {
        guard let cell = videoCell(at: indexPath)  else { return }
              
        let video = dataSource.video(at: indexPath)
        configure(cell: cell, for: video)
    }

    func loadThumbnail(for cell: VideoCell, video: PHAsset) {
        cell.identifier = video.localIdentifier

        cell.imageRequest = dataSource.thumbnail(for: video) { image, _ in
            let isCellRecycled = cell.identifier != video.localIdentifier

            guard !isCellRecycled,
                  let image = image else { return }

            cell.imageView.image = image
        }
    }

    func setGridContentMode(_ mode: AlbumGridContentMode, for cell: VideoCell, at indexPath: IndexPath, animated: Bool) {
        let video = dataSource.video(at: indexPath)
        cell.setGridContentMode(mode, forAspectRatio: video.dimensions, animated: animated)

    }

    func setGridContentModeForVisibleCells(_ mode: AlbumGridContentMode, animated: Bool) {
        collectionView.indexPathsForVisibleItems.forEach { indexPath in
            guard let cell = videoCell(at: indexPath) else { return }
            
            setGridContentMode(mode, for: cell, at: indexPath, animated: true)
        }
    }
}
