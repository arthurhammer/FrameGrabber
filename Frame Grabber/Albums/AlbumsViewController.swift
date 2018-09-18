import UIKit

class AlbumsViewController: UICollectionViewController {

    var dataSource = AlbumsDataSource() {
        didSet { configureDataSource() }
    }

    private var collectionViewDataSource: AlbumsCollectionViewDataSource!
    private lazy var albumCountFormatter = NumberFormatter()

    private let cellId = String(describing: AlbumCell.self)
    private let headerId = String(describing: AlbumHeader.self)
    private let headerHeight: CGFloat = 50

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        configureDataSource()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateThumbnailSize()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? AlbumViewController {
            prepareForAlbumSegue(with: controller)
        }
    }

    private func prepareForAlbumSegue(with destination: AlbumViewController) {
        guard let selection = collectionView?.indexPathsForSelectedItems?.first else { return }

        // Re-fetch album and contents as selected item can be outdated (i.e. data source
        // updates are pending in background). Result is nil if album was deleted.
        destination.album = collectionViewDataSource.fetchUpdate(forAlbumAt: selection)
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? AlbumCell else { return }
        cell.imageRequest = nil
    }

    // MARK: - Private

    private func configureViews() {
        clearsSelectionOnViewWillAppear = true
        collectionView?.alwaysBounceVertical = true

        let layout = CollectionViewTableLayout()
        collectionView?.collectionViewLayout = layout
        // In some cases, safe are content size isn't yet calculated on initialization.
        // Trigger layout update manually (`invalidate` doesn't work).
        layout.prepare()
    }

    private func configureDataSource() {
        guard isViewLoaded else { return }

        collectionViewDataSource = AlbumsCollectionViewDataSource(albumsDataSource: dataSource, sectionHeaderProvider: { [unowned self] in
            self.sectionHeader(at: $0)
        }, cellProvider: { [unowned self] in
            self.cell(for: $1, at: $0)
        })

        collectionViewDataSource.sectionsChangedHandler = { [weak self] sections in
            UIView.performWithoutAnimation {
                self?.collectionView?.reloadSections(sections)
            }
        }

        collectionView?.isPrefetchingEnabled = true
        collectionView?.dataSource = collectionViewDataSource
        collectionView?.prefetchDataSource = collectionViewDataSource

        updateThumbnailSize()
    }

    private func updateThumbnailSize() {
        guard let layout = collectionView?.collectionViewLayout as? CollectionViewTableLayout else { return }
        let height = layout.itemSize.height
        collectionViewDataSource.imageConfig.size = CGSize(width: height, height: height).scaledToScreen
    }

    private func cell(for album: Album, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? AlbumCell else { fatalError("Wrong cell identifier or type.") }
        configure(cell: cell, for: album)
        return cell
    }

    private func configure(cell: AlbumCell, for album: Album) {
        cell.identifier = album.assetCollection.localIdentifier
        cell.titleLabel.text = album.title
        cell.detailLabel.text = albumCountFormatter.string(from: album.count as NSNumber)

        loadThumbnail(for: cell, album: album)
    }

    private func loadThumbnail(for cell: AlbumCell, album: Album) {
        let albumId = album.assetCollection.localIdentifier
        cell.identifier = albumId

        cell.imageRequest = collectionViewDataSource.thumbnail(for: album) { image, _ in
            let isCellRecycled = cell.identifier != albumId

            guard !isCellRecycled, let image = image else { return }

            cell.imageView.image = image
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout / Section Headers

extension AlbumsViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard showsHeader(forSection: section) else { return .zero }
        return CGSize(width: 0, height: headerHeight)
    }

    private func showsHeader(forSection section: Int) -> Bool {
        guard let collectionViewDataSource = collectionViewDataSource else { return false }
        let section = collectionViewDataSource.sections[section]
        return (section.albums.count > 0) && (section.title != nil)
    }

    private func sectionHeader(at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView?.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerId, for: indexPath) as? AlbumHeader else { fatalError("Wrong view identifier or type.") }
        header.titleLabel.text = collectionViewDataSource.sections[indexPath.section].title
        return header
    }
}
