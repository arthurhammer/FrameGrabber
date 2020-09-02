import Combine
import PhotoAlbums
import Photos
import UIKit

enum AlbumsSection: Int {
    case smartAlbum
    case userAlbum
}

struct AlbumsSectionInfo: Hashable {
    let type: AlbumsSection
    let title: String?
    let albumCount: Int
    let isLoading: Bool
}

class AlbumsCollectionViewDataSource: UICollectionViewDiffableDataSource<AlbumsSectionInfo, AnyAlbum> {

    @Published var searchTerm: String?
    var imageOptions: PHImageManager.ImageOptions

    private let albumsDataSource: AlbumsDataSource
    private let imageManager: PHImageManager
    private var bindings = Set<AnyCancellable>()

    init(collectionView: UICollectionView,
         albumsDataSource: AlbumsDataSource,
         imageConfig: PHImageManager.ImageOptions = .init(size: .zero, mode: .aspectFill, requestOptions: .default()),
         imageManager: PHImageManager = .default(),
         sectionHeaderProvider: @escaping SupplementaryViewProvider,
         cellProvider: @escaping CellProvider) {

        self.albumsDataSource = albumsDataSource
        self.imageOptions = imageConfig
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

    func section(at index: Int) -> AlbumsSectionInfo {
        snapshot().sectionIdentifiers[index]
    }

    func album(at indexPath: IndexPath) -> AnyAlbum {
        guard let album = itemIdentifier(for: indexPath) else { fatalError("Invalid index path.") }
        return album
    }

    func fetchUpdate(forAlbumAt indexPath: IndexPath, filter: VideoTypesFilter) -> FetchedAlbum? {
        let album = self.album(at: indexPath).assetCollection
        let options = PHFetchOptions.assets(forAlbumType: album.assetCollectionType, videoFilter: filter)
        return FetchedAlbum.fetchUpdate(for: album, assetFetchOptions: options)
    }

    func thumbnail(for album: AnyAlbum, completionHandler: @escaping (UIImage?, PHImageManager.Info) -> ()) -> Cancellable? {
        guard let keyAsset = album.keyAsset else { return nil }
        return imageManager.requestImage(for: keyAsset, options: imageOptions, completionHandler: completionHandler)
    }

    // MARK: - Updating Data

    private func configureSearch() {
        $searchTerm
            .dropFirst()
            .throttle(for: 0.3, scheduler: DispatchQueue.main, latest: true)
            .map { $0?.trimmedOrNil }
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateData()
            }
            .store(in: &bindings)
    }

    private func configureDataSource() {
        albumsDataSource
            .$smartAlbums
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateData()
            }.store(in: &bindings)

        albumsDataSource
            .$userAlbums
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateData()
            }.store(in: &bindings)

        updateData()
    }

    private func updateData() {
        let smartAlbums = albumsDataSource.smartAlbums
        let userAlbums = albumsDataSource.userAlbums.searched(for: searchTerm, by: { $0.title })
        let isSearching = searchTerm?.trimmedOrNil != nil

        let sections = [
            AlbumsSectionInfo(type: .smartAlbum,
                              title: nil,
                              albumCount: smartAlbums.count,
                              isLoading: albumsDataSource.isLoadingSmartAlbums),

            AlbumsSectionInfo(type: .userAlbum,
                              title: UserText.albumsUserAlbumsHeader,
                              albumCount: userAlbums.count,
                              isLoading: albumsDataSource.isLoadingUserAlbums)
        ]

        var snapshot = NSDiffableDataSourceSnapshot<AlbumsSectionInfo, AnyAlbum>()

        snapshot.appendSections(sections)
        snapshot.appendItems(userAlbums, toSection: sections[1])

        if !isSearching {
            snapshot.appendItems(smartAlbums, toSection: sections[0])
        }

        apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - Utility

private extension Array {

    func searched(for searchTerm: String?, by key: (Element) -> String?) -> Self {
        guard let searchTerm = searchTerm?.trimmedOrNil else { return self }

        return filter {
            key($0)?.range(of: searchTerm, options: [.diacriticInsensitive, .caseInsensitive]) != nil
        }
    }
}
