import UIKit

class AlbumsViewController: UICollectionViewController {

    var dataSource: AlbumsDataSource? {
        didSet { configureDataSource() }
    }

    private var collectionViewDataSource: AlbumsCollectionViewDataSource?
    private lazy var albumCountFormatter = NumberFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        configureDataSource()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? AlbumViewController {
            prepareForAlbumSegue(with: controller)
        }
    }

    private func prepareForAlbumSegue(with destination: AlbumViewController) {
        guard let selection = collectionView?.indexPathsForSelectedItems?.first else { return }

        let type = destination.settings.videoType
        // Re-fetch album and contents as selected item can be outdated (i.e. data source
        // updates are pending in background). Result is nil if album was deleted.
        destination.album = collectionViewDataSource?.fetchUpdate(forAlbumAt: selection, containing: type)
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

        collectionView?.collectionViewLayout = AlbumsLayout { [weak self] newItemSize in
            self?.collectionViewDataSource?.imageOptions.size = newItemSize.scaledToScreen
        }
    }

    private func configureDataSource() {
        guard isViewLoaded else { return }

        guard let dataSource = dataSource else {
            collectionViewDataSource = nil
            collectionView.dataSource = nil
            return
        }

        collectionViewDataSource = AlbumsCollectionViewDataSource(albumsDataSource: dataSource, sectionHeaderProvider: { [unowned self] in
            self.sectionHeader(at: $0)
        }, cellProvider: { [unowned self] in
            self.cell(for: $1, at: $0)
        })

        collectionViewDataSource?.sectionsChangedHandler = { [weak self] sections in
            self?.collectionView?.reloadSections(sections)
        }

        collectionView?.isPrefetchingEnabled = true
        collectionView?.dataSource = collectionViewDataSource
        collectionView?.prefetchDataSource = collectionViewDataSource

        collectionView?.collectionViewLayout.invalidateLayout()
    }

    private func cell(for album: Album, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let type = AlbumsCollectionViewDataSource.SectionType(indexPath.section) else { fatalError("Wrong number of sections.") }
        let id = (type == .smartAlbum) ? "SmartAlbumCell" : "UserAlbumCell"
        guard let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as? AlbumCell else { fatalError("Wrong cell identifier or type.") }

        configure(cell: cell, for: album, type: type)
        return cell
    }

    private func configure(cell: AlbumCell, for album: Album, type: AlbumsCollectionViewDataSource.SectionType) {
        cell.identifier = album.id
        cell.titleLabel.text = album.title
        cell.detailLabel.text = albumCountFormatter.string(from: album.count as NSNumber)

        switch type {
        case .smartAlbum:
            cell.imageView.image = album.icon
            cell.imageView.tintColor = Style.Color.mainTint
        case .userAlbum:
            loadThumbnail(for: cell, album: album)
        }
    }

    private func loadThumbnail(for cell: AlbumCell, album: Album) {
        let albumId = album.id
        cell.identifier = albumId
        cell.imageView.image = album.icon

        cell.imageRequest = collectionViewDataSource?.thumbnail(for: album) { image, _ in
            let isCellRecycled = cell.identifier != albumId

            guard !isCellRecycled, let image = image else { return }

            cell.imageView.contentMode = .scaleAspectFill
            cell.imageView.image = image
        }
    }

    private func sectionHeader(at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView?.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: AlbumsHeader.name, for: indexPath) as? AlbumsHeader else { fatalError("Wrong view identifier or type.") }

        let section = collectionViewDataSource?.sections[indexPath.section]
        header.titleLabel.text = section?.title
        header.detailLabel.text = section?.subtitle
        header.activityIndicator.isHidden = section?.isLoading == false

        return header
    }
}
