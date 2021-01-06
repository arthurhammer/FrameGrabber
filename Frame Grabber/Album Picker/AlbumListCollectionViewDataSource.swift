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

class AlbumListCollectionViewDataSource: UICollectionViewDiffableDataSource<AlbumListSection, AnyAlbum> {

    @Published var searchTerm: String?
    
    var imageOptions = PHImageManager.ImageOptions()

    private let dataSource: AlbumsDataSource
    private let imageManager: PHImageManager
    private var bindings = Set<AnyCancellable>()
    
    init(
        collectionView: UICollectionView,
        albumsDataSource: AlbumsDataSource,
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

    func album(at indexPath: IndexPath) -> AnyAlbum {
        guard let album = itemIdentifier(for: indexPath) else { fatalError("Invalid index path.") }
        return album
    }

    func thumbnail(for album: AnyAlbum, completionHandler: @escaping (UIImage?, PHImageManager.Info) -> ()) -> Cancellable? {
        guard let keyAsset = album.keyAsset else { return nil }
        
        return imageManager.requestImage(
            for: keyAsset,
            options: imageOptions,
            completionHandler: completionHandler
        )
    }

    // MARK: - Updating Data

    private func configureDataSource() {
        dataSource
            .$smartAlbums
            .merge(with: dataSource.$userAlbums)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] test in
                self?.updateSections()
            }
            .store(in: &bindings)

        updateSections()
    }
    
    private func configureSearch() {
        $searchTerm
            .dropFirst()
            .throttle(for: 0.25, scheduler: DispatchQueue.main, latest: true)
            .map { $0?.trimmedOrNil }
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateSections()
            }
            .store(in: &bindings)
    }

    private func updateSections() {
        let isSearching = searchTerm?.trimmedOrNil != nil
        let smartAlbums = dataSource.smartAlbums
        let userAlbums = dataSource.userAlbums.searched(for: searchTerm, by: { $0.title })

        let sections = [
            AlbumListSection(
                type: .smartAlbum,
                title: nil,
                albumCount: smartAlbums.count,
                isLoading: dataSource.isLoadingSmartAlbums
            ),
            AlbumListSection(
                type: .userAlbum,
                title: UserText.albumsUserAlbumsHeader,
                albumCount: userAlbums.count,
                isLoading: dataSource.isLoadingUserAlbums
            )
        ]

        var snapshot = NSDiffableDataSourceSnapshot<AlbumListSection, AnyAlbum>()

        snapshot.appendSections(sections)

        if !isSearching {
            snapshot.appendItems(smartAlbums, toSection: sections[0])
        }
        
        snapshot.appendItems(userAlbums, toSection: sections[1])

        apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - Utility

private extension Array {

    func searched(for searchTerm: String?, by key: (Element) -> String?) -> Self {
        guard let searchTerm = searchTerm?.trimmedOrNil else { return self }

        let options: String.CompareOptions = [.diacriticInsensitive, .caseInsensitive]
        
        return filter {
            key($0)?.range(of: searchTerm, options: options) != nil
        }
    }
}
