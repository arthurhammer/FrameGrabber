import PhotoAlbums
import UIKit

protocol AlbumListViewControllerDelegate: class {
    func controller(_ controller: AlbumListViewController, didSelectAlbum album: AnyAlbum)
    func controllerDidSelectDone(_ controller: AlbumListViewController)
}

class AlbumListViewController: UICollectionViewController {
    
    weak var delegate: AlbumListViewControllerDelegate?

    let dataSource: AlbumsDataSource

    private lazy var collectionViewDataSource = makeCollectionViewDataSource()
    private lazy var albumCountFormatter = NumberFormatter()
    
    init?(
        coder: NSCoder,
        dataSource: AlbumsDataSource,
        delegate: AlbumListViewControllerDelegate? = nil
    ) {
        self.dataSource = dataSource
        self.delegate = delegate
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("A data source is required.")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()        
    }

    @objc private func done() {
        delegate?.controllerDidSelectDone(self)
    }

    // MARK: - UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let album = collectionViewDataSource.album(at: indexPath)
        delegate?.controller(self, didSelectAlbum: album)
    }

    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? AlbumCell)?.imageRequest = nil
    }

    // MARK: - Configuring

    private func configureViews() {
        collectionView.dataSource = collectionViewDataSource
        
        collectionView?.collectionViewLayout = AlbumListLayout { [weak self] newItemSize in
            self?.collectionViewDataSource.imageOptions.size = newItemSize.scaledToScreen
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(done)
        )

        configureSearch()
    }

    private func configureSearch() {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func makeCollectionViewDataSource() -> AlbumListCollectionViewDataSource {
        assert(isViewLoaded)
        
        return AlbumListCollectionViewDataSource(
            collectionView: collectionView,
            albumsDataSource: dataSource,
            sectionHeaderProvider: { [unowned self] _, _, indexPath  in
                self.sectionHeader(at: indexPath)
            }, cellProvider: { [unowned self] _, indexPath, album in
                self.cell(for: album, at: indexPath)
            }
        )
    }
    
    // MARK: - Cells

    private func cell(for album: AnyAlbum, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = AlbumListSection.SectionType(indexPath.section),
            let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: section.cellIdentifier, for: indexPath) as? AlbumCell else { fatalError("Wrong cell identifier or type or unknown section.") }

        configure(cell: cell, for: album, section: section)
        
        return cell
    }

    private func configure(cell: AlbumCell, for album: AnyAlbum, section: AlbumListSection.SectionType) {
        cell.identifier = album.id
        cell.titleLabel.text = album.title
        cell.detailLabel.text = albumCountFormatter.string(from: album.count as NSNumber)
        cell.imageView.image = album.icon

        switch section {
        
        case .smartAlbum:
            cell.imageView.tintColor = .accent
        
        case .userAlbum:
            loadThumbnail(for: cell, album: album)
        }

        cell.isAccessibilityElement = true
        cell.accessibilityLabel = album.title
    }

    private func loadThumbnail(for cell: AlbumCell, album: AnyAlbum) {
        cell.identifier = album.id

        cell.imageRequest = collectionViewDataSource.thumbnail(for: album) { image, _ in
            guard cell.identifier == album.id,
                  let image = image else { return }

            cell.imageView.contentMode = .scaleAspectFill
            cell.imageView.image = image
        }
    }

    private func sectionHeader(at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView?.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: AlbumListHeader.className, for: indexPath) as? AlbumListHeader else { fatalError("Wrong view identifier or type or no data source.") }

        let section = collectionViewDataSource.section(at: indexPath.section)
        
        header.titleLabel.text = section.title
        header.detailLabel.text = albumCountFormatter.string(from: section.albumCount as NSNumber)
        header.detailLabel.isHidden = section.isLoading
        header.activityIndicator.isHidden = !section.isLoading

        return header
    }
}

// MARK: - Searching

extension AlbumListViewController: UISearchBarDelegate, UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        collectionViewDataSource.searchTerm = searchController.searchBar.text
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        stopSearchingWhenSearchBarEmpty(searchBar)
    }

    private func stopSearchingWhenSearchBarEmpty(_ searchBar: UISearchBar) {
        guard searchBar.text?.trimmed.nilIfEmpty == nil else { return }

        searchBar.text = nil
        
        // Setting `isActive` directly tends to dismiss the entire albums view controller.
        DispatchQueue.main.async {
            guard let searchController = self.navigationItem.searchController,
                  searchController.isActive else { return }
            
            searchController.isActive = false
        }
    }
}

// MARK: - Utilities

private extension AlbumListSection.SectionType {
    
    var cellIdentifier: String {
        switch self {
        case .smartAlbum: return "SmartAlbumCell"
        case .userAlbum: return "UserAlbumCell"
        }
    }
}
