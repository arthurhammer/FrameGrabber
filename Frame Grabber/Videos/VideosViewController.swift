import UIKit
import Photos

class VideosViewController: UICollectionViewController {

    // Album is nil if deleted.
    var album: FetchedAlbum? {
        get { return dataSource?.album }
        set { configureDataSource(with: newValue) }
    }

    private var dataSource: VideosCollectionViewDataSource!

    private lazy var layout = CollectionViewGridLayout()
    private lazy var durationFormatter = VideoDurationFormatter()
    private let cellId = String(describing: VideoCell.self)

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        clearsSelectionOnViewWillAppear = true
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        layout.updateItemSize(forBoundingSize: size)
        updateThumbnailSize()

        coordinator.animate(alongsideTransition: { _ in
            self.collectionView?.layoutIfNeeded()
        }, completion: nil)

        super.viewWillTransition(to: size, with: coordinator)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? PlayerViewController {
            prepareForPlayerSegue(with: controller)
        }
    }

    private func prepareForPlayerSegue(with destination: PlayerViewController) {
        guard let selectedIndexPath = collectionView?.indexPathsForSelectedItems?.first else { fatalError("Segue without selection or asset") }

        let selectedAsset = dataSource.video(at: selectedIndexPath)
        destination.videoLoader = VideoManager(asset: selectedAsset)
    }
}

// MARK: - UICollectionViewDelegate

extension VideosViewController {

    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? VideoCell else { return }
        // Cancel generating thumbnail
        cell.imageRequest = nil
    }
}

// MARK: - Private

private extension VideosViewController {

    func configureViews() {
        collectionView?.delegate = self
        collectionView?.backgroundColor = .mainBackground
        collectionView?.collectionViewLayout = layout
        layout.updateItemSize(forBoundingSize: view.bounds.size)
    }

    func configureDataSource(with album: FetchedAlbum?) {
        dataSource = VideosCollectionViewDataSource(album: album) { [unowned self] in
            self.cell(for: $1, at: $0)
        }

        dataSource.albumDeletedHandler = { [weak self] in
            // On deletion, just show empty screen.
            self?.updateAlbumData()
            self?.collectionView?.reloadData()
        }

        dataSource.albumChangedHandler = { [weak self] in
            self?.updateAlbumData()
        }

        dataSource.videosChangedHandler = { [weak self] changeDetails in
            self?.collectionView?.applyPhotoLibraryChanges(for: changeDetails)
        }

        collectionView?.isPrefetchingEnabled = true
        collectionView?.dataSource = dataSource
        collectionView?.prefetchDataSource = dataSource

        updateAlbumData()
        updateThumbnailSize()
    }

    func updateAlbumData() {
        title = dataSource?.album?.title ?? ""  // won't accept nil
    }

    func updateThumbnailSize() {
        dataSource.imageConfig.size = layout.itemSize.scaledToScreen
    }

    func cell(for video: PHAsset, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? VideoCell else { fatalError("Wrong cell identifier or type.") }
        configure(cell: cell, for: video)
        return cell
    }

    func configure(cell: VideoCell, for video: PHAsset) {
        cell.durationLabel.text = durationFormatter.string(from: video.duration)
        cell.favoritedImageView.isHidden = !video.isFavorite
        loadThumbnail(for: cell, video: video)
    }

    func loadThumbnail(for cell: VideoCell, video: PHAsset) {
        cell.videoIdentifier = video.localIdentifier

        cell.imageRequest = dataSource.thumbnail(for: video) { image, _ in
            let isCellRecycled = cell.videoIdentifier != video.localIdentifier

            guard let image = image,
                !isCellRecycled else { return }

            cell.imageView.image = image
        }
    }
}
