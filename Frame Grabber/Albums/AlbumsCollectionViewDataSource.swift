import UIKit
import Photos
import Combine

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

    var imageOptions: PHImageManager.ImageOptions

    private var sections = [AlbumsSectionInfo]()
    private let albumsDataSource: AlbumsDataSource
    private let imageManager: PHImageManager

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
        // the initializer even returns...
        DispatchQueue.main.async {
            self.configureDataSource()
        }
    }

    // MARK: Data

    func section(at index: Int) -> AlbumsSectionInfo {
        sections[index]
    }

    func album(at indexPath: IndexPath) -> Album {
        switch AlbumsSection(indexPath.section)! {
        case .smartAlbum:
            return albumsDataSource.smartAlbums[indexPath.item]
        case .userAlbum:
            return albumsDataSource.userAlbums[indexPath.item]
        }
    }

    func fetchUpdate(forAlbumAt indexPath: IndexPath, containing videoType: VideoType) -> FetchedAlbum? {
        let album = self.album(at: indexPath).assetCollection
        let options = PHFetchOptions.assets(forAlbumType: album.assetCollectionType, videoType: videoType)
        return FetchedAlbum.fetchUpdate(for: album, assetFetchOptions: options)
    }

    func thumbnail(for album: Album, completionHandler: @escaping (UIImage?, PHImageManager.Info) -> ()) -> Cancellable? {
        guard let keyAsset = album.keyAsset else { return nil }
        return imageManager.requestImage(for: keyAsset, options: imageOptions, completionHandler: completionHandler)
    }

    private func configureDataSource() {
        albumsDataSource.smartAlbumsChangedHandler = { [weak self] albums in
            self?.updateData()
        }

        albumsDataSource.userAlbumsChangedHandler = { [weak self] albums in
            self?.updateData()
        }

        updateData()
    }

    private func updateData() {
        sections = [
            AlbumsSectionInfo(type: .smartAlbum,
                              title: nil,
                              albumCount: albumsDataSource.smartAlbums.count,
                              isLoading: !albumsDataSource.didInitializeSmartAlbums),

            AlbumsSectionInfo(type: .userAlbum,
                              title: NSLocalizedString("albums.userAlbumsHeader", value: "My Albums", comment: "User photo albums section header"),
                              albumCount: albumsDataSource.userAlbums.count,
                              isLoading: !albumsDataSource.didInitializeUserAlbums)
        ]

        var snapshot = NSDiffableDataSourceSnapshot<AlbumsSectionInfo, AnyAlbum>()

        snapshot.appendSections(sections)
        snapshot.appendItems(albumsDataSource.smartAlbums, toSection: sections[0])
        snapshot.appendItems(albumsDataSource.userAlbums, toSection: sections[1])

        apply(snapshot, animatingDifferences: true)
    }
}
