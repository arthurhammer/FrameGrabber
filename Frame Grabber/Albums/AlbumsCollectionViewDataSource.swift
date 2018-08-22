import UIKit
import Photos

class AlbumsCollectionViewDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {

    var sectionsChangedHandler: ((IndexSet) -> ())?

    var imageConfig: ImageConfig {
        didSet { imageManager.stopCachingImagesForAllAssets() }
    }

    private var sections: [Section] = [.empty, .empty]
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

        configureSectionChangeHandlers()
    }

    deinit {
        imageManager.stopCachingImagesForAllAssets()
    }

    func title(forSection section: Int) -> String? {
        return sections[section].title
    }

    func album(at indexPath: IndexPath) -> Album {
        return sections[indexPath.section].albums[indexPath.item]
    }

    func albums(at indexPaths: [IndexPath]) -> [Album] {
        return indexPaths.map(album)
    }

    func thumbnail(for album: Album, resultHandler: @escaping (UIImage?, ImageManagerRequest.Info) -> ()) -> ImageRequest? {
        guard let keyAsset = album.keyAsset else { return nil }

        return ImageRequest(imageManager: imageManager,
                            asset: keyAsset,
                            targetSize: imageConfig.size,
                            contentMode: imageConfig.mode,
                            options: imageConfig.options,
                            resultHandler: resultHandler)
    }

    func fetchUpdate(forAlbumAt indexPath: IndexPath) -> FetchedAlbum? {
        let assetFetchOptions = sections[indexPath.section].assetFetchOptions
        return FetchedAlbum.fetchUpdate(for: album(at: indexPath), assetFetchOptions: assetFetchOptions)
    }

    private func configureSectionChangeHandlers() {
        albumsDataSource.smartAlbumsChangedHandler = { [weak self] albums in
            self?.imageManager.stopCachingImagesForAllAssets()
            self?.sections[0] = Section(title: NSLocalizedString("Library", comment: ""), albums: albums, assetFetchOptions: .smartAlbumVideos())
            self?.sectionsChangedHandler?([0])
        }

        albumsDataSource.userAlbumsChangedHandler = { [weak self] albums in
            self?.imageManager.stopCachingImagesForAllAssets()
            self?.sections[1] = Section(title: NSLocalizedString("My Albums", comment: ""), albums: albums, assetFetchOptions: .userAlbumVideos())
            self?.sectionsChangedHandler?([1])
        }
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

        imageManager.startCachingImages(for: keyAssets,
                                        targetSize: imageConfig.size,
                                        contentMode: imageConfig.mode,
                                        options: imageConfig.options)
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let keyAssets = albums(at: indexPaths).compactMap { $0.keyAsset }

        imageManager.stopCachingImages(for: keyAssets,
                                       targetSize: imageConfig.size,
                                       contentMode: imageConfig.mode,
                                       options: imageConfig.options)
    }
}

private struct Section {
    let title: String?
    let albums: [Album]
    let assetFetchOptions: PHFetchOptions

    static var empty = Section(title: nil, albums: [], assetFetchOptions: .init())
}
