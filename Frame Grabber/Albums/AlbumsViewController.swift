import UIKit

class AlbumsViewController: UICollectionViewController {

    var dataSource: AlbumsCollectionViewDataSource!

    private let cellId = String(describing: AlbumCell.self)

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        configureDataSource()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updateLayout(for: size)
        updateThumbnailSize()

        coordinator.animate(alongsideTransition: { _ in
            self.collectionView?.layoutIfNeeded()
        }, completion: nil)

        super.viewWillTransition(to: size, with: coordinator)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? VideosViewController {
            prepareForVideosSegue(with: controller)
        }
    }

    private func prepareForVideosSegue(with destination: VideosViewController) {
        guard let selection = collectionView?.indexPathsForSelectedItems?.first else { return }

        // Re-fetch album and contents as selected item can be outdated (i.e. data source
        // updates are pending in background). Result is nil if album was deleted.
        destination.album = dataSource.fetchUpdate(forAlbumAt: selection)
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? AlbumCell else { return }
        // Cancel generating thumbnail.
        cell.imageRequest = nil
    }

    // MARK: - Private

    private func configureViews() {
        clearsSelectionOnViewWillAppear = true
        collectionView?.alwaysBounceVertical = true
        updateLayout(for: view.bounds.size)
    }

    private func configureDataSource() {
        dataSource = AlbumsCollectionViewDataSource { [unowned self] in
            self.cell(for: $1, at: $0)
        }

        dataSource.sectionsChangedHandler = { [weak self] sections in
            self?.collectionView?.reloadSections(sections)
        }

        collectionView?.isPrefetchingEnabled = true
        collectionView?.dataSource = dataSource
        collectionView?.prefetchDataSource = dataSource

        updateThumbnailSize()
    }

    private func updateLayout(for boundindSize: CGSize) {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else { return }

        let itemHeight: CGFloat = 90
        layout.itemSize = CGSize(width: boundindSize.width, height: itemHeight)
        layout.minimumLineSpacing = 0
    }

    private func updateThumbnailSize() {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let height = layout.itemSize.height
        dataSource.imageConfig.size = CGSize(width: height, height: height).scaledToScreen
    }

    private func cell(for album: Album, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? AlbumCell else { fatalError("Wrong cell identifier or type.") }
        configure(cell: cell, for: album)
        return cell
    }

    private func configure(cell: AlbumCell, for album: Album) {
        cell.identifier = album.assetCollection.localIdentifier
        cell.titleLabel.text = album.title
        cell.detailLabel.text = album.count.flatMap { "\($0)" }

        loadThumbnail(for: cell, album: album)
    }

    private func loadThumbnail(for cell: AlbumCell, album: Album) {
        let albumId = album.assetCollection.localIdentifier
        cell.identifier = albumId

        cell.imageRequest = dataSource.thumbnail(for: album) { image, _ in
            let isCellRecycled = cell.identifier != albumId

            guard !isCellRecycled, let image = image else { return }

            cell.imageView.image = image
        }
    }
}
