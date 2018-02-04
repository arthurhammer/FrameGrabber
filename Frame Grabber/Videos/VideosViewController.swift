import UIKit
import Photos

class VideosViewController: UICollectionViewController {

    private var dataSource: VideosCollectionViewDataSource?
    private lazy var layout = CollectionViewGridLayout()
    private lazy var durationFormatter = VideoDurationFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        configureDataSource()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        layout.updateItemSize()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? PlayerViewController {
            prepareForPlayerSegue(with: controller)
        }
    }

    private func prepareForPlayerSegue(with destination: PlayerViewController) {
        guard let selectedIndexPath = collectionView?.indexPathsForSelectedItems?.first,
            let selectedAsset = dataSource?.asset(at: selectedIndexPath) else { fatalError("Segue without selection or asset") }

        destination.modalPresentationCapturesStatusBarAppearance = true
        destination.delegate = self
        destination.videoLoader = VideoLoader(asset: selectedAsset)

        // Don't scroll to top while player is presented (`overCurrentContext`)
        collectionView?.scrollsToTop = false
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

// MARK: - PlayerViewControllerDelegate

extension VideosViewController: PlayerViewControllerDelegate {

    func playerViewControllerDone() {
        collectionView?.scrollsToTop = true
        collectionView?.clearSelection()
    }
}

// MARK: - Private

private extension VideosViewController {

    func configureViews() {
        collectionView?.delegate = self
        collectionView?.backgroundColor = .mainBackground
        collectionView?.collectionViewLayout = layout
        layout.updateItemSize()
    }

    func configureDataSource() {
        // Layout needs to be configured before data source for valid thumbnail size
        let thumbnailSize = layout.itemSize.scaledToScreen

        dataSource = VideosCollectionViewDataSource(collectionView: collectionView!, thumbnailSize: thumbnailSize) { [unowned self] indexPath, asset in
            return self.cell(for: asset, at: indexPath)
        }
    }

    func cell(for asset: PHAsset, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? VideoCell else { fatalError("Wrong cell identifier or type.") }

        configure(cell: cell, for: asset)

        return cell
    }

    func configure(cell: VideoCell, for asset: PHAsset) {
        cell.assetIdentifier = asset.localIdentifier
        cell.durationLabel.text = durationFormatter.string(from: asset.duration)
        cell.favoritedImageView.isHidden = !asset.isFavorite

        cell.imageRequest = dataSource?.thumbnail(for: asset) { image, _ in
            let isCellRecycled = cell.assetIdentifier != asset.localIdentifier

            guard let image = image,
                !isCellRecycled else { return }

            cell.imageView.image = image
        }
    }
}

private let cellId = String(describing: VideoCell.self)
