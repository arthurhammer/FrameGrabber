import UIKit
import Photos

struct AlbumsSection {
    let title: String?
    var albums: [Album]
    let assetFetchOptions: PHFetchOptions
}

class AlbumsCollectionViewDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {

    var sectionsChangedHandler: ((IndexSet) -> ())?

    var imageConfig: ImageConfig {
        didSet { imageManager.stopCachingImagesForAllAssets() }
    }

    private(set) var sections = [AlbumsSection]()

    private let albumsDataSource: AlbumsDataSource
    private let sectionHeaderProvider: (IndexPath) -> UICollectionReusableView
    private let cellProvider: (IndexPath, Album) -> UICollectionViewCell
    private let imageManager: PHCachingImageManager

    init(albumsDataSource: AlbumsDataSource = .init(),
         imageConfig: ImageConfig = .init(),
         imageManager: PHCachingImageManager = .init(),
         sectionHeaderProvider: @escaping (IndexPath) -> UICollectionReusableView,
         cellProvider: @escaping (IndexPath, Album) -> UICollectionViewCell) {

        self.albumsDataSource = albumsDataSource
        self.imageConfig = imageConfig
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
        return sections[indexPath.section].albums[indexPath.item]
    }

    func albums(at indexPaths: [IndexPath]) -> [Album] {
        return indexPaths.map(album)
    }

    func thumbnail(for album: Album, resultHandler: @escaping (UIImage?, PHImageManager.Info) -> ()) -> ImageRequest? {
        guard let keyAsset = album.keyAsset else { return nil }

        return imageManager.requestImage(for: keyAsset, config: imageConfig, resultHandler: resultHandler)
    }

    func fetchUpdate(forAlbumAt indexPath: IndexPath) -> FetchedAlbum? {
        let assetFetchOptions = sections[indexPath.section].assetFetchOptions
        return FetchedAlbum.fetchUpdate(for: album(at: indexPath).assetCollection, assetFetchOptions: assetFetchOptions)
    }

    private func configureSections() {
        sections = [
            AlbumsSection(title: NSLocalizedString("Library", comment: ""), albums: albumsDataSource.smartAlbums, assetFetchOptions: .smartAlbumVideos()),
            AlbumsSection(title: NSLocalizedString("My Albums", comment: ""), albums: albumsDataSource.userAlbums, assetFetchOptions: .userAlbumVideos())
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
        return sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[section].albums.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return cellProvider(indexPath, album(at: indexPath))
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return sectionHeaderProvider(indexPath)
    }

    // MARK: UICollectionViewDataSourcePrefetching

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let keyAssets = albums(at: indexPaths).compactMap { $0.keyAsset }

        imageManager.startCachingImages(for: keyAssets, targetSize: imageConfig.size, contentMode: imageConfig.mode, options: imageConfig.options)
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let keyAssets = albums(at: indexPaths).compactMap { $0.keyAsset }

        imageManager.stopCachingImages(for: keyAssets, targetSize: imageConfig.size, contentMode: imageConfig.mode, options: imageConfig.options)
    }
}
