import PhotoAlbums
import Photos
import UIKit

class AlbumViewController: UICollectionViewController {

    /// nil if deleted.
    var album: FetchedAlbum? {
        get { return dataSource?.album }
        set { configureDataSource(with: newValue) }
    }

    /// The title that will be used when album is `nil`.
    var defaultTitle = UserText.albumDefaultTitle {
        didSet { updateViews() }
    }

    /// The most recently selected asset.
    private(set) var selectedAsset: PHAsset?

    var settings: UserDefaults = .standard

    @IBOutlet private var contentModeBarItem: UIBarButtonItem!
    @IBOutlet private var filterControl: VideoTypeFilterControl!

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
        navigationController?.navigationBar.shadowImage = nil
        navigationController?.navigationBar.layer.shadowOpacity = 0
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateContentInset()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? EditorViewController {
            prepareForPlayerSegue(with: controller)
        }
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

    // Rename
    @IBAction func didChangeThumbnailContentMode() {
        let newMode = settings.albumGridContentMode.toggled

        settings.albumGridContentMode = newMode

        collectionView.indexPathsForVisibleItems.forEach { indexPath in
            guard let cell = videoCell(at: indexPath) else { return }
            setThumbnailContentMode(newMode, for: cell, at: indexPath, animated: true)
        }

        updateViews()
    }

    @IBAction func didChangeVideoFilter(_ sender: VideoTypeFilterControl) {
        dataSource?.filter = VideoTypesFilter(sender.selectedSegmentIndex) ?? .all
    }

    /// Selects `selectedAsset` in the collection view.
    func restoreSelection(animated: Bool) {
        let selectedIndexPath = selectedAsset.flatMap { dataSource?.indexPath(of: $0) }
        collectionView.selectItem(at: selectedIndexPath, animated: animated, scrollPosition: [])
    }

    // MARK: - Collection View Data Source & Delegate

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? VideoCell else { return }
        setThumbnailContentMode(settings.albumGridContentMode, for: cell, at: indexPath, animated: false)
    }

    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? VideoCell)?.imageRequest = nil
    }

    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let video = dataSource?.video(at: indexPath) else { return nil }

        let sourceImageView = videoCell(at: indexPath)?.imageView

        return .videoCellContextMenu(for: video, at: indexPath) { [weak self] in
            self?.imagePreviewController(for: sourceImageView)
        }
        toggleFavoriteHandler: { [weak self] _ in
            self?.dataSource?.toggleFavorite(for: video)
        }
        deleteHandler: { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
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
            self.performSegue(withIdentifier: EditorViewController.name, sender: nil)
        }
    }
}

// MARK: - Private

private extension AlbumViewController {

    func configureViews() {
        clearsSelectionOnViewWillAppear = false
        collectionView?.alwaysBounceVertical = true
        collectionView.backgroundView = emptyView

        collectionView?.collectionViewLayout = AlbumGridLayout { [weak self] newItemSize in
            self?.dataSource?.imageOptions.size = newItemSize.scaledToScreen
        }

        configureFilterControl()
        updateViews()
    }

    func updateViews() {
        title = dataSource?.album?.title ?? defaultTitle

        emptyView.type = dataSource?.filter ?? .all
        emptyView.isEmpty = dataSource?.isEmpty ?? true

        filterControl.selectedSegmentIndex = (dataSource?.filter ?? .all).rawValue
        contentModeBarItem.image = settings.albumGridContentMode.toggled.image
    }

    func configureFilterControl() {
        let margin: CGFloat = 16
        view.addSubview(filterControl)

        filterControl.translatesAutoresizingMaskIntoConstraints = false
        filterControl.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        view.safeAreaLayoutGuide.leadingAnchor.constraint(lessThanOrEqualTo: filterControl.leadingAnchor , constant: -margin).isActive = true
        view.safeAreaLayoutGuide.trailingAnchor.constraint(greaterThanOrEqualTo: filterControl.trailingAnchor, constant: margin).isActive = true
        // 0 for notched phones, `margin`` for non-notched phones.
        view.safeAreaLayoutGuide.bottomAnchor.constraint(greaterThanOrEqualTo: filterControl.bottomAnchor, constant: 0).isActive = true
        let bottomConstraint = view.bottomAnchor.constraint(equalTo: filterControl.bottomAnchor, constant: margin)
        bottomConstraint.priority = .init(rawValue: 999)
        bottomConstraint.isActive = true
    }

    func updateContentInset() {
        let spacing: CGFloat = 8
        let filterControlAdjust = filterControl.bounds.height + spacing
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: filterControlAdjust, right: 0)
        collectionView.verticalScrollIndicatorInsets = collectionView.contentInset
    }

    func configureDataSource(with album: FetchedAlbum?) {
        dataSource = AlbumCollectionViewDataSource(album: album, settings: settings) { [unowned self] in
            self.cell(for: $1, at: $0)
        }

        dataSource?.albumDeletedHandler = { [weak self] in
            // Just show empty screen.
            self?.updateViews()
            self?.collectionView?.reloadData()
        }

        dataSource?.albumChangedHandler = { [weak self] in
            self?.updateViews()
        }

        dataSource?.videosChangedHandler = { [weak self] changeDetails in
            self?.updateViews()

            guard let changeDetails = changeDetails else {
                self?.collectionView.reloadData()
                return
            }

            self?.collectionView?.applyPhotoLibraryChanges(for: changeDetails, cellConfigurator: {
                self?.reconfigure(cellAt: $0)
            })
        }

        collectionView?.isPrefetchingEnabled = true
        collectionView?.dataSource = dataSource
        collectionView?.prefetchDataSource = dataSource

        updateViews()
        collectionView?.collectionViewLayout.invalidateLayout()
    }


    // MARK: Cell Handling

    func cell(for video: PHAsset, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: VideoCell.name, for: indexPath) as? VideoCell else { fatalError("Wrong cell identifier or type.") }
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

            guard !isCellRecycled, let image = image else { return }

            cell.imageView.image = image
        }
    }

    func setThumbnailContentMode(_ mode: AlbumGridContentMode, for cell: VideoCell, at indexPath: IndexPath, animated: Bool) {
        guard let video = dataSource?.video(at: indexPath) else { return }

        let duration = animated ? 0.15 : 0
        let targetSize = mode.thumbnailSize(forAssetDimensions: video.dimensions, in: cell.bounds.size)

        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
            cell.imageContainerWidthConstraint.constant = targetSize.width
            cell.imageContainerHeightConstraint.constant = targetSize.height
            cell.imageContainer.layoutIfNeeded()
        })
    }

    func videoCell(at indexPath: IndexPath) -> VideoCell? {
        collectionView.cellForItem(at: indexPath) as? VideoCell
    }
}
