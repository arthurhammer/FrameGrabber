import Combine
import PhotoAlbums
import Photos
import UIKit

struct AlbumListSection: Hashable {
    
    enum SectionType: Int {
        case smartAlbum
        case userAlbum
    }
    
    let type: SectionType
    let title: String?
    let albumCount: Int
    let isLoading: Bool
}

class AlbumListCollectionViewDataSource: UICollectionViewDiffableDataSource<AlbumListSection, Album> {

    @Published var searchTerm: String?
    
    private let dataSource: AlbumPickerDataSource
    private let imageManager: PHImageManager
    private var bindings = Set<AnyCancellable>()
    
    init(
        collectionView: UICollectionView,
        albumsDataSource: AlbumPickerDataSource,
        imageManager: PHImageManager = .default(),
        sectionHeaderProvider: @escaping SupplementaryViewProvider,
        cellProvider: @escaping CellProvider
    ) {
        self.dataSource = albumsDataSource
        self.imageManager = imageManager

        super.init(collectionView: collectionView, cellProvider: cellProvider)

        self.supplementaryViewProvider = sectionHeaderProvider

        // Otherwise, synchronously asks the view controller for cells and headers before
        // the initializer even returns.
        DispatchQueue.main.async {
            self.configureSearch()
            self.configureDataSource()
        }
    }

    // MARK: - Accessing Data

    func section(at index: Int) -> AlbumListSection {
        snapshot().sectionIdentifiers[index]
    }

    func album(at indexPath: IndexPath) -> Album {
        guard let album = itemIdentifier(for: indexPath) else { fatalError("Invalid index path.") }
        return album
    }

    func thumbnail(
        for album: Album,
        options: PHImageManager.ImageOptions,
        completionHandler: @escaping (UIImage?, PHImageManager.Info) -> ()
    ) -> Cancellable? {
        guard let keyAsset = album.keyAsset else { return nil }
        
        return imageManager.requestImage(
            for: keyAsset,
            options: options,
            completionHandler: completionHandler
        )
    }

    // MARK: - Updating Data

    private func configureDataSource() {
        dataSource
            .smartAlbumsProvider.albumsPublisher
            .merge(with: dataSource.userAlbumsProvider.albumsPublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateSections()
            }
            .store(in: &bindings)

        updateSections()
    }
    
    private func configureSearch() {
        $searchTerm
            .dropFirst()
            .throttle(for: 0.25, scheduler: DispatchQueue.main, latest: true)
            .map { $0?.trimmed.nilIfEmpty }
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateSections()
            }
            .store(in: &bindings)
    }

    private func updateSections() {
        let isSearching = searchTerm?.trimmed.nilIfEmpty != nil
        let smartAlbums = dataSource.smartAlbumsProvider.albums
        let userAlbums = dataSource.userAlbumsProvider.albums.searched(
            for: searchTerm,
            by: { $0.title }
        )

        let smartAlbumsSection = AlbumListSection(
            type: .smartAlbum,
            title: nil,
            albumCount: smartAlbums.count,
            isLoading: dataSource.smartAlbumsProvider.isLoading
        )
        
        let userAlbumsSection = AlbumListSection(
            type: .userAlbum,
            title: Localized.albumsUserAlbumsHeader,
            albumCount: userAlbums.count,
            isLoading: dataSource.userAlbumsProvider.isLoading
        )

        var snapshot = NSDiffableDataSourceSnapshot<AlbumListSection, Album>()

        if !isSearching {
            snapshot.appendSections([smartAlbumsSection])
            snapshot.appendItems(smartAlbums, toSection: smartAlbumsSection)
        }
        
        snapshot.appendSections([userAlbumsSection])
        snapshot.appendItems(userAlbums, toSection: userAlbumsSection)
        
        apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - Utility

private extension Array {

    func searched(for searchTerm: String?, by key: (Element) -> String?) -> Self {
        guard let searchTerm = searchTerm?.trimmed.nilIfEmpty else { return self }

        let options: String.CompareOptions = [.diacriticInsensitive, .caseInsensitive]
        
        return filter {
            key($0)?.range(of: searchTerm, options: options) != nil
        }
    }
}
