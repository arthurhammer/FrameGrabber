import PhotoAlbums
import Photos
import UIKit

protocol AlbumListViewControllerDelegate: class {
    func controller(_ controller: AlbumListViewController, didSelectAlbum album: Album)
    func controllerDidSelectDone(_ controller: AlbumListViewController)
}

class AlbumListViewController: UICollectionViewController {
    
    weak var delegate: AlbumListViewControllerDelegate?

    let dataSource: AlbumPickerDataSource

    private lazy var collectionViewDataSource = makeCollectionViewDataSource()
    private lazy var albumCountFormatter = NumberFormatter()
    
    init?(
        coder: NSCoder,
        dataSource: AlbumPickerDataSource,
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentContentSize(comparedTo: previousTraitCollection) {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
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
        
        collectionView?.collectionViewLayout = AlbumListLayout { [weak self] index in
            self?.collectionViewDataSource.section(at: index).type.axis ?? .vertical
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

    private func cell(for album: Album, at indexPath: IndexPath) -> UICollectionViewCell {
        let section = collectionViewDataSource.section(at: indexPath.section).type
        let id = section.cellIdentifier
        
        guard let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as? AlbumCell else { fatalError("Wrong cell identifier or type or unknown section.") }

        configure(cell: cell, for: album, section: section)
        
        return cell
    }

    private func configure(cell: AlbumCell, for album: Album, section: AlbumListSection.SectionType) {
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = album.title

        cell.identifier = album.id
        cell.titleLabel.text = album.title
        cell.detailLabel.text = albumCountFormatter.string(from: album.count as NSNumber)
        cell.selectedBackgroundView?.backgroundColor = (section == .userAlbum) ? .cellSelection : nil

        loadThumbnail(for: cell, album: album)
    }

    private func loadThumbnail(for cell: AlbumCell, album: Album) {
        cell.identifier = album.id
        let size = cell.imageView.bounds.size.scaledToScreen
        let options = PHImageManager.ImageOptions(size: size)

        cell.imageRequest = collectionViewDataSource.thumbnail(for: album, options: options) {
            (image, _) in
            
            guard cell.identifier == album.id,
                  let image = image else { return }

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
        stopSearchingIfSearchBarEmpty(searchBar)
    }

    private func stopSearchingIfSearchBarEmpty(_ searchBar: UISearchBar) {
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
    
    var axis: AlbumListLayout.SectionType {
        switch self {
        case .smartAlbum: return .horizontal
        case .userAlbum: return .vertical
        }
    }
    
    var cellIdentifier: String {
        switch self {
        case .smartAlbum: return "SmartAlbumCell"
        case .userAlbum: return "UserAlbumCell"
        }
    }
}
