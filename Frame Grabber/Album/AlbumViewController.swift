import PhotoAlbums
import Photos
import PhotosUI
import UIKit

class AlbumViewController: UICollectionViewController {

    /// nil if deleted.
    var album: FetchedAlbum? {
        get { return dataSource?.album }
        set { configureDataSource(with: newValue) }
    }

    /// The title that will be used when album is `nil`.
    var defaultTitle = UserText.albumDefaultTitle {
        didSet { updateViews(animated: false) }
    }

    /// The most recently selected asset.
    private(set) var selectedAsset: PHAsset?

    var settings: UserDefaults = .standard

    @IBOutlet private var viewSettingsButton: AlbumViewSettingsButton!
    @IBOutlet private var infoBarItem: UIBarButtonItem!
    @IBOutlet private var extendPhotoSelectionBarItem: UIBarButtonItem!

    private lazy var emptyView = EmptyAlbumView()
    private var dataSource: AlbumCollectionViewDataSource?
    private lazy var durationFormatter = VideoDurationFormatter()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
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

        if let selectedAsset = dataSource?.video(at: selectedIndexPath) {
            self.selectedAsset = selectedAsset
            let thumbnail = videoCell(at: selectedIndexPath)?.imageView.image
            destination.videoController = VideoController(asset: selectedAsset, previewImage: thumbnail)
        }
    }

    // MARK: - Actions

    /// Selects `selectedAsset` in the collection view.
    func restoreSelection(animated: Bool) {
        let selectedIndexPath = selectedAsset.flatMap { dataSource?.indexPath(of: $0) }
        collectionView.selectItem(at: selectedIndexPath, animated: animated, scrollPosition: [])
    }

    @IBAction private func extendPhotoSelection() {
        if #available(iOS 14, *) {
            dataSource?.photoLibrary.presentLimitedLibraryPicker(from: self)
        } 
    }

    // MARK: - Collection View Data Source & Delegate

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? VideoCell else { return }
        
        setGridContentMode(settings.albumGridContentMode, for: cell, at: indexPath, animated: false)
    }

    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? VideoCell)?.imageRequest = nil
    }

    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let video = dataSource?.video(at: indexPath) else { return nil }

        let sourceImageView = videoCell(at: indexPath)?.imageView
        
        let previewProvider = { [weak self] in
            self?.imagePreviewController(for: sourceImageView)
        }

        return AlbumCellContextMenu.menu(
            for: video,
            at: indexPath,
            previewProvider: previewProvider
        ) { [weak self] selection in

            self?.handleCellContextMenuSelection(selection, for: video)
        }
    }
    
    private func handleCellContextMenuSelection(_ selection: AlbumCellContextMenu.Selection, for video: PHAsset) {
        let animationDelay = 0.2
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) { [weak self] in
            switch selection {
            
            case .favorite:
                self?.dataSource?.toggleFavorite(for: video)
                
            case .delete:
                self?.dataSource?.delete(video)
            }
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
    
    // TODO
    func controller(_ controller: AlbumsViewController, didSelectAlbum album: AnyAlbum) {
        let assetCollection = album.assetCollection
        
        let options = PHFetchOptions.assets(
            forAlbumType: assetCollection.assetCollectionType,
            videoFilter: dataSource?.filter ?? .all
        )
        
        self.album = FetchedAlbum.fetchUpdate(for: assetCollection, assetFetchOptions: options)
    }
}

private extension AlbumViewController {
    
    // MARK: Configuring

    func configureViews() {
        clearsSelectionOnViewWillAppear = false
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundView = emptyView

        collectionView.collectionViewLayout = AlbumGridLayout { [weak self] newItemSize in
            self?.dataSource?.imageOptions.size = newItemSize.scaledToScreen
        }

        viewSettingsButton.add(to: view)
        updateViews(animated: false)
    }

    func updateViews(animated: Bool) {
        guard isViewLoaded else { return }
        
        title = dataSource?.album?.title ?? defaultTitle

        emptyView.type = dataSource?.filter ?? .all
        emptyView.isEmpty = dataSource?.isEmpty ?? true

        updateViewSettingsButton(animated: animated)
        updateNavigationBar()
    }
    
    func updateNavigationBar() {
        navigationController?.navigationBar.shadowImage = nil
        navigationController?.navigationBar.layer.shadowOpacity = 0
        
        if dataSource?.isAuthorizationLimited == true {
            navigationItem.rightBarButtonItems = [infoBarItem, extendPhotoSelectionBarItem]
        } else {
            navigationItem.rightBarButtonItems = [infoBarItem]
        }

        // Use the controller's `title` instead.
        navigationItem.backButtonTitle = nil
        navigationItem.backBarButtonItem?.title = nil

        if #available(iOS 14.0, *) {
            navigationItem.backButtonDisplayMode = .minimal
        }
    }

    func configureDataSource(with album: FetchedAlbum?) {
        dataSource = AlbumCollectionViewDataSource(album: album, settings: settings) { [unowned self] in
            self.cell(for: $1, at: $0)
        }

        dataSource?.albumDeletedHandler = { [weak self] in
            // Just show empty screen.
            self?.updateViews(animated: false)
            self?.collectionView?.reloadData()
        }

        dataSource?.albumChangedHandler = { [weak self] in
            self?.updateViews(animated: false)
        }

        dataSource?.videosChangedHandler = { [weak self] changeDetails in
            self?.updateViews(animated: false)

            guard let changeDetails = changeDetails else {
                self?.collectionView?.reloadData()
                return
            }

            self?.collectionView?.applyPhotoLibraryChanges(for: changeDetails, cellConfigurator: {
                self?.reconfigure(cellAt: $0)
            })
        }

        collectionView?.isPrefetchingEnabled = true
        collectionView?.dataSource = dataSource
        collectionView?.prefetchDataSource = dataSource

        updateViews(animated: false)
        collectionView?.collectionViewLayout.invalidateLayout()
    }

    // MARK: View Settings Button

    func updateViewSettingsButton(animated: Bool) {
        let duration = animated ? 0.1 : 0
        let filter = dataSource?.filter ?? .all

        UIView.animate(withDuration: duration) {
            self.viewSettingsButton.setTitle(filter.title, for: .normal)
            self.viewSettingsButton.layoutIfNeeded()
        }

        if #available(iOS 14, *) {
            viewSettingsButton.showsMenuAsPrimaryAction = true
            
            viewSettingsButton.menu = AlbumViewSettingsMenu.menu(
                forCurrentFilter: filter,
                gridMode: settings.albumGridContentMode,
                handler: { [weak self] selection in
                    DispatchQueue.main.async {
                        self?.handleViewSettingsMenuSelection(selection)
                    }
                }
            )
        } else {
            viewSettingsButton.addTarget(self, action: #selector(showViewSettingsAlertSheet), for: .touchUpInside)
        }
    }

    @objc func showViewSettingsAlertSheet() {
        let controller = AlbumViewSettingsMenu.alertController(
            forCurrentFilter: dataSource?.filter ?? .all,
            gridMode: settings.albumGridContentMode,
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
            dataSource?.filter = filter
            
        case .gridMode(let mode):
            settings.albumGridContentMode = mode
            setGridContentModeForVisibleCells(mode, animated: true)
        }

        self.updateViewSettingsButton(animated: true)
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
        guard let cell = videoCell(at: indexPath),
              let video = dataSource?.video(at: indexPath) else { return }

        configure(cell: cell, for: video)
    }

    func loadThumbnail(for cell: VideoCell, video: PHAsset) {
        cell.identifier = video.localIdentifier

        cell.imageRequest = dataSource?.thumbnail(for: video) { image, _ in
            let isCellRecycled = cell.identifier != video.localIdentifier

            guard !isCellRecycled,
                  let image = image else { return }

            cell.imageView.image = image
        }
    }

    func setGridContentMode(_ mode: AlbumGridContentMode, for cell: VideoCell, at indexPath: IndexPath, animated: Bool) {
        guard let video = dataSource?.video(at: indexPath) else { return }
        
        cell.setGridContentMode(mode, forAspectRatio: video.dimensions, animated: animated)

    }

    func setGridContentModeForVisibleCells(_ mode: AlbumGridContentMode, animated: Bool) {
        collectionView.indexPathsForVisibleItems.forEach { indexPath in
            guard let cell = videoCell(at: indexPath) else { return }
            
            setGridContentMode(mode, for: cell, at: indexPath, animated: true)
        }
    }
}
