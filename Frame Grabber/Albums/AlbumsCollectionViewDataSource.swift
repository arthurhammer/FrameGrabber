import UIKit
import Photos
import Combine

struct AlbumsSection {
    let title: String?
    var albums: [Album]
}

class AlbumsCollectionViewDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {

    var sectionsChangedHandler: ((IndexSet) -> ())?

    var imageOptions: PHImageManager.ImageOptions {
        didSet { imageManager.stopCachingImagesForAllAssets() }
    }

    private(set) var sections = [AlbumsSection]()

    private let albumsDataSource: AlbumsDataSource
    private let sectionHeaderProvider: (IndexPath) -> UICollectionReusableView
    private let cellProvider: (IndexPath, Album) -> UICollectionViewCell
    private let imageManager: PHCachingImageManager

    init(albumsDataSource: AlbumsDataSource,
         imageConfig: PHImageManager.ImageOptions = .init(size: .zero, mode: .aspectFill, requestOptions: .default()),
         imageManager: PHCachingImageManager = .init(),
         sectionHeaderProvider: @escaping (IndexPath) -> UICollectionReusableView,
         cellProvider: @escaping (IndexPath, Album) -> UICollectionViewCell) {

        self.albumsDataSource = albumsDataSource
        self.imageOptions = imageConfig
        self.imageManager = imageManager
        self.sectionHeaderProvider = sectionHeaderProvider
        self.cellProvider = cellProvider

        super.init()

        configureSections()
    }

    deinit {
        imageManager.stopCachingImagesForAllAssets()
    }

    // MARK: Data

    func album(at indexPath: IndexPath) -> Album {
        sections[indexPath.section].albums[indexPath.item]
    }

    func thumbnail(for album: Album, completionHandler: @escaping (UIImage?, PHImageManager.Info) -> ()) -> Cancellable? {
        guard let keyAsset = album.keyAsset else { return nil }

        return imageManager.requestImage(for: keyAsset, options: imageOptions, completionHandler: completionHandler)
    }

    func fetchUpdate(forAlbumAt indexPath: IndexPath, containing videoType: VideoType) -> FetchedAlbum? {
        let album = self.album(at: indexPath).assetCollection
        let options = PHFetchOptions.assets(forAlbumType: album.assetCollectionType, videoType: videoType)
        return FetchedAlbum.fetchUpdate(for: album, assetFetchOptions: options)
    }

    private func safeAlbums(at indexPaths: [IndexPath]) -> [Album] {
        let safeIndexPaths = indexPaths
            .filter { $0.section < sections.count }
            .filter { $0.item < sections[$0.section].albums.count }

        return safeIndexPaths.map(album)
    }

    private func configureSections() {
        sections = [
            AlbumsSection(title: NSLocalizedString("albums.smartAlbumsHeader", value: "Library", comment: "Smart photo albums section header"), albums: albumsDataSource.smartAlbums),
            AlbumsSection(title: NSLocalizedString("albums.userAlbumsHeader", value: "My Albums", comment: "User photo albums section header"), albums: albumsDataSource.userAlbums)
        ]

        albumsDataSource.smartAlbumsChangedHandler = { [weak self] albums in
            self?.updateSection(at: 0, with: albums)
        }

        albumsDataSource.userAlbumsChangedHandler = { [weak self] albums in
            self?.updateSection(at: 1, with: albums)
        }
    }

    private func updateSection(at index: Int, with albums: [Album]) {
        imageManager.stopCachingImagesForAllAssets()
        sections[index].albums = albums
        sectionsChangedHandler?(IndexSet([index]))
    }

    // MARK: UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sections[section].albums.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        cellProvider(indexPath, album(at: indexPath))
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        sectionHeaderProvider(indexPath)
    }

    // MARK: UICollectionViewDataSourcePrefetching

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        // Index paths might not exist anymore in the model.
        let keyAssets = safeAlbums(at: indexPaths).compactMap { $0.keyAsset }
        imageManager.startCachingImages(for: keyAssets, targetSize: imageOptions.size, contentMode: imageOptions.mode, options: imageOptions.requestOptions)
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let keyAssets = safeAlbums(at: indexPaths).compactMap { $0.keyAsset }
        imageManager.stopCachingImages(for: keyAssets, targetSize: imageOptions.size, contentMode: imageOptions.mode, options: imageOptions.requestOptions)
    }
}
