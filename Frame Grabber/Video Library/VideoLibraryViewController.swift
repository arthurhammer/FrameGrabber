import UIKit
import Photos

protocol VideoLibraryViewControllerDelegate: class {
    func didSelectVideo(_ video: Video)
}

class VideoLibraryViewController: UICollectionViewController {

    weak var delegate: VideoLibraryViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    /// Start fetching and displaying videos and observing Photo Library changes.
    /// This is to avoid triggering premature Photo Library access dialogs.
    func fetchVideos() {
        guard !videosFetched else { return }
        
        videosFetched = true
        PHPhotoLibrary.shared().register(self)
        collectionView?.reloadData()
        updateViews()
        selectFirstVideo()
    }

    // MARK: - Private IVars

    @IBOutlet private var backgroundView: VideoLibraryBackgroundView!

    private var videosFetched = false

    private lazy var videosFetchResult: PHFetchResult<PHAsset> = {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssets(with: .video, options: fetchOptions)
    }()

    private var cellIdentifier = String(describing: VideoCell.self)

    private lazy var imageManager = PHCachingImageManager()

    // TODO: sizing + constraints
    private var itemSpacing: CGFloat = 1

    private lazy var itemSize: CGSize = {
        let itemsPerRow: CGFloat = 4
        let viewWidth = view.frame.size.width
        let width = floor((viewWidth - (itemsPerRow - 1) * itemSpacing) / itemsPerRow)
        return CGSize(width: width, height: width)
    }()

    private lazy var thumbnailSize: CGSize = {
        let scale = UIScreen.main.scale
        return CGSize(width: self.itemSize.width * scale, height: self.itemSize.height * scale)
    }()
}

// MARK: - UICollectionViewDataDelegate

extension VideoLibraryViewController {

    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        // Don't re-select if already selected
        let alreadySelected = (collectionView.indexPathsForSelectedItems ?? []).contains(indexPath)
        return !alreadySelected
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = videosFetchResult.object(at: indexPath.row)
        delegate?.didSelectVideo(Video(asset: asset))
    }

    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let assets = [videosFetchResult.object(at: indexPath.item)]
        imageManager.stopCachingImages(for: assets, targetSize: itemSize, contentMode: .aspectFill, options: nil)
    }
}

// MARK: - UICollectionViewDataSource

extension VideoLibraryViewController {

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videosFetched ? videosFetchResult.count : 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? VideoCell else {
            fatalError("Wrong cell identifier or type.")
        }

        let asset = videosFetchResult.object(at: indexPath.item)
        configure(cell: cell, for: asset)
        return cell
    }
}

// MARK: - UICollectionViewDataSourcePrefetching

extension VideoLibraryViewController: UICollectionViewDataSourcePrefetching {

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let assets = videosFetchResult.objects(at: indexPaths.indexSet)
        imageManager.startCachingImages(for: assets, targetSize: itemSize, contentMode: .aspectFill, options: nil)
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let assets = videosFetchResult.objects(at: indexPaths.indexSet)
        imageManager.stopCachingImages(for: assets, targetSize: itemSize, contentMode: .aspectFill, options: nil)
    }
}

// MARK: - PHPhotoLibraryChangeObserver

extension VideoLibraryViewController: PHPhotoLibraryChangeObserver {

    // Note: If the currently selected video was updated or removed, we update the collection
    //       view but don't propagate the change to the video view controller so we don't
    //       disrupt the user working on the current video.
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let changes = changeInstance.changeDetails(for: videosFetchResult) else { return }

        DispatchQueue.main.sync {
            videosFetchResult = changes.fetchResultAfterChanges
            imageManager.stopCachingImagesForAllAssets()

            if changes.hasIncrementalChanges {
                collectionView?.performBatchUpdates({
                    // For indexes to make sense, updates must be in this order: delete, insert, reload, move
                    if let removed = changes.removedIndexes, !removed.isEmpty {
                        collectionView?.deleteItems(at: removed.indexPaths)
                    }

                    if let inserted = changes.insertedIndexes, !inserted.isEmpty {
                        collectionView?.insertItems(at: inserted.indexPaths)
                    }

                    if let changed = changes.changedIndexes, !changed.isEmpty {
                        collectionView?.reloadItems(at: changed.indexPaths)
                    }

                    changes.enumerateMoves { fromIndex, toIndex in
                        self.collectionView?.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                      to: IndexPath(item: toIndex, section: 0))
                    }
                })
            } else {
                collectionView?.reloadData()
            }

            updateViews()
        }
    }
}

// MARK: - Private

private extension VideoLibraryViewController {

    func configureViews() {
        let cellNib = UINib(nibName: cellIdentifier, bundle: nil)
        collectionView?.register(cellNib, forCellWithReuseIdentifier: cellIdentifier)

        collectionView?.isPrefetchingEnabled = true
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.prefetchDataSource = self
        collectionView?.backgroundColor = .videoLibraryBackgroundColor
        collectionView?.backgroundView = backgroundView

        // TODO: sizing
        collectionView?.contentInset = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)

        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = itemSize
            layout.minimumInteritemSpacing = 6  // TODO: constants
            layout.minimumLineSpacing = 6
        }
    }

    func updateViews() {
        backgroundView.isHidden = videosFetchResult.count > 0
    }

    func configure(cell: VideoCell, for asset: PHAsset) {
        cell.assetIdentifier = asset.localIdentifier
        cell.durationLabel.text = VideoDurationFormatter().string(from: asset.duration)
        cell.favoritedImageView.isHidden = !asset.isFavorite

        imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
            // Cell may have been recycled by the time thumbnail is ready
            guard cell.assetIdentifier == asset.localIdentifier else { return }
            cell.thumbnailImage = image
        })
    }

    func selectFirstVideo() {
        guard let firstVideo = videosFetchResult.firstObject else { return }
        let index = IndexPath(item: 0, section: 0)
        collectionView?.selectItem(at: index, animated: true, scrollPosition: .left)
        delegate?.didSelectVideo(Video(asset: firstVideo))
    }
}
