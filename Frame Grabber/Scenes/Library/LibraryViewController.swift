import Combine
import Photos
import PhotosUI
import UIKit

protocol AlbumViewControllerDelegate: class {
    func controllerDidSelectAlbumPicker(_ controller: LibraryViewController)
    func controllerDidSelectFilePicker(_ controller: LibraryViewController)
    func controllerDidSelectCamera(_ controller: LibraryViewController)
    func controller(_ controller: LibraryViewController, didSelectEditorForAsset asset: PHAsset, previewImage: UIImage?)
}

class LibraryViewController: UICollectionViewController {
    
    weak var delegate: AlbumViewControllerDelegate?
            
    override var title: String? {
        didSet { titleButton.setTitle(title, for: .normal, animated: false) }
    }
    
    var album: PHAssetCollection? {
        dataSource.album
    }

    /// The asset that is the the source/target for the zoom push/pop transition, typically the last
    /// selected asset.
    var transitionAsset: PHAsset? {
        didSet { select(asset: transitionAsset, animated: false) }
    }

    @IBOutlet private var titleButton: UIButton!
    @IBOutlet private var filterButton: LibraryFilterButton!
    @IBOutlet private var aboutBarItem: UIBarButtonItem!

    private lazy var emptyView = EmptyLibraryView()
    private lazy var durationFormatter = VideoDurationFormatter()
    private var bindings = Set<AnyCancellable>()
    
    private lazy var dataSource: LibraryCollectionViewDataSource = LibraryCollectionViewDataSource {
        [unowned self] in
        self.cell(for: $1, at: $0)
    }

    static let contentModeAnimationDuration: TimeInterval = 0.15
    
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
    
    // MARK: - Setting Albums
    
    func setAlbum(_ album: PHAssetCollection) {
        dataSource.setAlbum(album)
    }

    // MARK: - Actions

    func select(asset: PHAsset?, animated: Bool) {
        let indexPath = asset.flatMap { dataSource.indexPath(of: $0) }
        collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: [])
    }
    
    @objc private func showAlbumPicker() {
        delegate?.controllerDidSelectAlbumPicker(self)
    }
    
    @IBAction private func showFilePicker() {
        delegate?.controllerDidSelectFilePicker(self)
    }
    
    @IBAction private func showCamera() {
        delegate?.controllerDidSelectCamera(self)
    }

    // MARK: - Collection View Data Source & Delegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let video = dataSource.video(at: indexPath) else { return }
        let thumbnail = videoCell(at: indexPath)?.imageView.image
        delegate?.controller(self, didSelectEditorForAsset: video, previewImage: thumbnail)
    }

    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? VideoCell)?.imageRequest = nil
    }

    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let video = dataSource.video(at: indexPath) else { return nil}
        let thumbnail = videoCell(at: indexPath)?.imageView.image

        return VideoCellContextMenu.configuration(
            for: video,
            initialPreviewImage: thumbnail
        ) { [weak self] selection in

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.handleCellContextMenuSelection(selection, for: video)
            }
        }
    }
    
    private func handleCellContextMenuSelection(_ selection: VideoCellContextMenu.Selection, for video: PHAsset) {
        guard let video = dataSource.currentVideo(for: video) else { return }
        
        switch selection {
        
        case .favorite:
            dataSource.toggleFavorite(for: video)
            
        case .delete:
            dataSource.delete(video)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let video = configuration.identifier as? PHAsset,
              let indexPath = dataSource.indexPath(of: video),
              let cell = videoCell(at: indexPath) else { return nil }

        return UITargetedPreview(view: cell.imageContainer)
    }

    override func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        self.collectionView(collectionView, previewForHighlightingContextMenuWithConfiguration: configuration)
    }

    override func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        // Video might've been deleted or changed during preview.
        guard let video = configuration.identifier as? PHAsset,
              let updatedVideo = dataSource.currentVideo(for: video),
              let indexPath = dataSource.indexPath(of: updatedVideo) else { return }

        animator.addAnimations {
            let thumbnail = self.videoCell(at: indexPath)?.imageView.image
            
            self.delegate?.controller(
                self,
                didSelectEditorForAsset: updatedVideo,
                previewImage: thumbnail
            )
        }
    }
}

private extension LibraryViewController {
    
    // MARK: Configuring

    func configureViews() {
        collectionView.collectionViewLayout = LibraryGridLayout { [weak self] newItemSize in
            self?.dataSource.imageOptions.size = newItemSize.scaledToScreen
        }
        
        collectionView.isPrefetchingEnabled = true
        collectionView.dataSource = dataSource
        collectionView.backgroundView = emptyView
        collectionView.collectionViewLayout.invalidateLayout()

        titleButton.configureDynamicTypeLabel()
        titleButton.configureTrailingAlignedImage()        
        navigationItem.titleView = UIView()
        
        if #available(iOS 14, *) {
            filterButton.showsMenuAsPrimaryAction = true
        } else {
            let action = #selector(showViewSettingsAlertSheet)
            filterButton.addTarget(self, action: action, for: .touchUpInside)
        }
        
        filterButton.add(to: view)
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
            title = dataSource.album?.localizedTitle ?? UserText.albumFallbackTitle
            titleButton.addTarget(self, action: #selector(showAlbumPicker), for: .touchUpInside)
        }

        emptyView.type = dataSource.filter
        emptyView.isEmpty = dataSource.isEmpty && !dataSource.isUpdating

        updateViewSettingsButton()
        updateNavigationBar()
    }
    
    func updateNavigationBar() {
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layer.shadowOpacity = 0

        if #available(iOS 14.0, *) {
            navigationItem.backButtonDisplayMode = .minimal
        }
    }
        
    func configureDataSource() {
        dataSource.$album
            .combineLatest(
                dataSource.$isUpdating.removeDuplicates(),
                dataSource.$assetsChanged
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateViews()
            }.store(in: &bindings)

        dataSource.$assetsChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.collectionView.reloadData(animated: true)
            }.store(in: &bindings)
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
        filterButton.setTitle(dataSource.filter.title, for: .normal, animated: false)
        
        if #available(iOS 14, *) {
            filterButton.menu = LibraryFilterMenu.menu(
                with: dataSource.filter,
                gridMode: dataSource.gridMode,
                handler: { [weak self] selection in
                    DispatchQueue.main.async {
                        self?.handleViewSettingsMenuSelection(selection)
                    }
                }
            )
        }
    }

    @objc func showViewSettingsAlertSheet() {
        let controller = LibraryFilterMenu.alertController(
            with: dataSource.filter,
            gridMode: dataSource.gridMode,
            handler: { [weak self] selection in
                DispatchQueue.main.async {
                    self?.handleViewSettingsMenuSelection(selection)
                }
            }
        )

        controller.popoverPresentationController?.sourceView = filterButton
        presentAlert(controller)
    }

    func handleViewSettingsMenuSelection(_ selection: LibraryFilterMenu.Selection) {
        UISelectionFeedbackGenerator().selectionChanged()

        switch selection {
        
        case .filter(let filter):
            dataSource.filter = filter
            
        case .gridMode(let mode):
            dataSource.gridMode = mode
            setGridMode(mode, animated: true)
        }

        updateViewSettingsButton()
    }

    func updateContentInsetForViewSettingsButton() {
        let topMargin: CGFloat = 8
        let bottomInset = filterButton.bounds.height + topMargin

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
        cell.setGridContentMode(dataSource.gridMode, forAspectRatio: video.dimensions)
        
        loadThumbnail(for: cell, video: video)
    }

    func reconfigure(cellAt indexPath: IndexPath) {
        guard let cell = videoCell(at: indexPath),
              let video = dataSource.video(at: indexPath) else { return }
              
        configure(cell: cell, for: video)
    }

    func loadThumbnail(for cell: VideoCell, video: PHAsset) {
        cell.identifier = video.localIdentifier

        cell.imageRequest = dataSource.thumbnail(for: video) { image, _ in
            guard cell.identifier == video.localIdentifier,
                  let image = image else { return }

            cell.imageView.image = image
        }
    }

    func setGridMode(_ mode: LibraryGridMode, for cell: VideoCell, at indexPath: IndexPath) {
        guard let video = dataSource.video(at: indexPath) else { return }
        cell.setGridContentMode(mode, forAspectRatio: video.dimensions)

    }

    func setGridMode(_ mode: LibraryGridMode, animated: Bool) {
        guard animated else {
            collectionView.reloadData()
            return
        }
        
        let animations = {
            self.collectionView.indexPathsForVisibleItems.forEach { indexPath in
                guard let cell = self.videoCell(at: indexPath) else { return }
                self.setGridMode(mode, for: cell, at: indexPath)
            }
        }
        
        // Animate visible cells, then reload off-screen enqueued cells.
        UIView.animate(
            withDuration: LibraryViewController.contentModeAnimationDuration,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseInOut],
            animations: animations,
            completion: { _ in
                self.collectionView.reloadData()
            }
        )
    }
}
