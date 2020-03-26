import UIKit
import Photos

class AlbumViewController: UICollectionViewController {

    /// nil if deleted.
    var album: FetchedAlbum? {
        get { return dataSource?.album }
        set { configureDataSource(with: newValue) }
    }

    /// The title that will be used when album is `nil`
    var defaultTitle = UserText.albumDefaultTitle {
        didSet { updateViews() }
    }

    /// The most recently selected asset.
    private(set) var selectedAsset: PHAsset?
    var settings: UserDefaults = .standard

    @IBOutlet private var filterControl: VideoTypeFilterControl!
    private var dataSource: AlbumCollectionViewDataSource?
    private lazy var emptyView = EmptyAlbumView()
    private lazy var durationFormatter = VideoDurationFormatter()

    // MARK: Lifecycle

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

    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let video = dataSource?.video(at: indexPath) else { return nil }

        let sourceImageView = videoCell(at: indexPath)?.imageView

        return .menu(for: video, previewProvider: { [weak self] in
            self?.imagePreviewController(for: sourceImageView)
        }, toggleFavoriteAction: { [weak self] _ in
            self?.dataSource?.toggleFavorite(for: video)
        }, deleteAction: { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self?.dataSource?.delete(video)
            }
        })
    }

    override func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let video = configuration.identifier as? PHAsset,
            let indexPath = dataSource?.indexPath(of: video) else { return }

        animator.addAnimations {
            self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            self.performSegue(withIdentifier: EditorViewController.name, sender: nil)
        }
    }

    /// Selects `selectedAsset` in the collection view.
    func restoreSelection(animated: Bool) {
        let selectedIndexPath = selectedAsset.flatMap { dataSource?.indexPath(of: $0) }
        collectionView.selectItem(at: selectedIndexPath, animated: animated, scrollPosition: [])
    }
}

// MARK: - UICollectionViewDelegate

extension AlbumViewController {

    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? VideoCell else { return }
        cell.imageRequest = nil
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

    func updateViews() {
        title = dataSource?.album?.title ?? defaultTitle
        emptyView.type = dataSource?.type ?? .any
        emptyView.isEmpty = dataSource?.isEmpty ?? true
        filterControl.selectedSegmentIndex = (dataSource?.type ?? .any).rawValue
    }

    func updateContentInset() {
        let spacing: CGFloat = 8
        let filterControlAdjust = filterControl.bounds.height + spacing
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: filterControlAdjust, right: 0)
        collectionView.verticalScrollIndicatorInsets = collectionView.contentInset
    }

    @IBAction func filterDidChange(_ sender: VideoTypeFilterControl) {
        dataSource?.type = VideoType(sender.selectedSegmentIndex) ?? .any
    }

    func cell(for video: PHAsset, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: VideoCell.name, for: indexPath) as? VideoCell else { fatalError("Wrong cell identifier or type.") }
        configure(cell: cell, for: video)
        return cell
    }

    func configure(cell: VideoCell, for video: PHAsset) {
        cell.durationLabel.text = video.isVideo ? durationFormatter.string(from: video.duration) : nil
        cell.favoritedImageView.isHidden = !video.isFavorite
        cell.gradientView.isHidden = !video.isFavorite && !video.isVideo
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

    func videoCell(at indexPath: IndexPath) -> VideoCell? {
        collectionView.cellForItem(at: indexPath) as? VideoCell
    }
}
