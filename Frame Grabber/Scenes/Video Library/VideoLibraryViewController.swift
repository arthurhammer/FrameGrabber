import UIKit
import Photos

class VideoLibraryViewController: UICollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()

        // If authorized, show videos right away.
        // Otherwise, wait for explicit user interaction via status view controller
        // to avoid unwanted authorization dialogs.
        if statusViewController.isAuthorized {
            startShowingVideos()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView?.clearSelection()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? PlayerViewController,
            let indexPath = collectionView?.indexPathsForSelectedItems?.first,
            let asset = dataSource?.asset(at: indexPath ) {

            controller.video = Video(asset: asset)
        }
    }

    // MARK: Private

    private let statusViewController = VideoLibraryStatusViewController()
    private var dataSource: VideoLibraryCollectionViewDataSource?
    private lazy var layout = Layout(viewWidth: self.view.frame.size.width)
    private lazy var durationFormatter = VideoDurationFormatter()
}

// MARK: - UICollectionViewDelegate

extension VideoLibraryViewController {

    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? VideoCell else { return }
        // Cancel generating thumbnail
        cell.imageRequest = nil
    }
}

// MARK: - VideoLibraryCollectionViewDataSourceDelegate

extension VideoLibraryViewController: VideoLibraryCollectionViewDataSourceDelegate {

    func didChange() {
        updateStatusViewController()
    }
}

// MARK: - VideoLibraryStatusViewControllerDelegate

extension VideoLibraryViewController: VideoLibraryStatusViewControllerDelegate {

    func didAuthorize() {
        startShowingVideos()
    }
}

// MARK: - Private

private extension VideoLibraryViewController {

    func configureViews() {
        collectionView?.delegate = self
        collectionView?.backgroundColor = .mainBackground
        collectionView?.collectionViewLayout = layout.collectionViewLayout
        addStatusViewController()
    }

    func addStatusViewController() {
        statusViewController.delegate = self

        // Embed status view controller as background view
        addChildViewController(statusViewController)
        collectionView?.backgroundView = statusViewController.view
        statusViewController.didMove(toParentViewController: self)
    }

    func updateStatusViewController() {
        statusViewController.isEmpty = dataSource?.isEmpty ?? true
    }

    func startShowingVideos() {
        dataSource = VideoLibraryCollectionViewDataSource(collectionView: collectionView!, thumbnailSize: layout.itemSize.scaledToScreen) { [unowned self] indexPath, asset in
            return self.cell(for: asset, at: indexPath)
        }

        updateStatusViewController()
    }

    func cell(for asset: PHAsset, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: Identifier.cell, for: indexPath) as? VideoCell else {
            fatalError("Wrong cell identifier or type.")
        }

        configure(cell: cell, for: asset)
        return cell
    }

    func configure(cell: VideoCell, for asset: PHAsset) {
        cell.assetIdentifier = asset.localIdentifier
        cell.durationLabel.text = durationFormatter.string(from: asset.duration)
        cell.favoritedImageView.isHidden = !asset.isFavorite

        cell.imageRequest = dataSource?.thumbnail(for: asset) { image, _ in
            // Cell may have been recycled by the time thumbnail is ready
            guard cell.assetIdentifier == asset.localIdentifier else { return }
            cell.imageView.image = image
        }
    }
}

private struct Identifier {
    static let cell = VideoCell.className
    static let videoPlayerSegue = PlayerViewController.className
}

private struct Layout {
    let collectionViewLayout: UICollectionViewFlowLayout
    let viewWidth: CGFloat
    let itemsPerRow: CGFloat
    let itemSpacing: CGFloat

    var itemSize: CGSize {
        let itemWidth = floor((viewWidth - (itemsPerRow - 1) * itemSpacing) / itemsPerRow)
        return CGSize(width: itemWidth, height: itemWidth)
    }

    init(itemsPerRow: CGFloat = 3, itemSpacing: CGFloat = 1, viewWidth: CGFloat) {
        self.itemsPerRow = itemsPerRow
        self.itemSpacing = itemSpacing
        self.viewWidth = viewWidth

        self.collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.itemSize = itemSize
        collectionViewLayout.minimumLineSpacing = itemSpacing
        collectionViewLayout.minimumInteritemSpacing = itemSpacing
    }
}
