import Combine
import Photos
import UIKit

protocol LibraryGridViewControllerDelegate: class {
    func controller(_ controller: LibraryGridViewController, didSelectAsset asset: PHAsset, previewImage: UIImage?)
}

class LibraryGridViewController: UICollectionViewController {
    
    static let contentModeAnimationDuration: TimeInterval = 0.15
    
    weak var delegate: LibraryGridViewControllerDelegate?
    
    // todo
    var transitionAsset: PHAsset? {
        didSet { select(asset: transitionAsset, animated: false) }
    }
    
    private lazy var emptyView = EmptyLibraryView()
    private lazy var durationFormatter = VideoDurationFormatter()
    private var bindings = Set<AnyCancellable>()
    
    private lazy var dataSource: LibraryCollectionViewDataSource = LibraryCollectionViewDataSource {
        [unowned self] in
        self.cell(for: $1, at: $0)
    }
    
    func select(asset: PHAsset?, animated: Bool) {
        let indexPath = asset.flatMap { dataSource.indexPath(of: $0) }
        collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: [])
    }
    
    // MARK: - Collection View Data Source & Delegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let video = dataSource.video(at: indexPath) else { return }
        let thumbnail = videoCell(at: indexPath)?.imageView.image
        delegate?.controller(self, didSelectAsset: video, previewImage: thumbnail)
    }

    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? VideoCell)?.imageRequest = nil
    }

    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let video = dataSource.video(at: indexPath) else { return nil}
        let thumbnail = videoCell(at: indexPath)?.imageView.image

        return VideoCellContextMenu.configuration(
            for: video,
            initialPreviewImage: thumbnail
        ) { [weak self] selection in

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.handleCellContextMenuSelection(selection, for: video)
            }
        }
    }
    
    private func handleCellContextMenuSelection(_ selection: VideoCellContextMenu.Selection, for video: PHAsset) {
        guard let video = dataSource.currentVideo(for: video) else { return }
        
        switch selection {
        
        case .favorite:
            dataSource.toggleFavorite(for: video)
            
        case .delete:
            dataSource.delete(video)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let video = configuration.identifier as? PHAsset,
              let indexPath = dataSource.indexPath(of: video),
              let cell = videoCell(at: indexPath) else { return nil }

        return UITargetedPreview(view: cell.imageContainer)
    }

    override func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        self.collectionView(collectionView, previewForHighlightingContextMenuWithConfiguration: configuration)
    }

    override func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        // Video might've been deleted or changed during preview.
        guard let video = configuration.identifier as? PHAsset,
              let updatedVideo = dataSource.currentVideo(for: video),
              let indexPath = dataSource.indexPath(of: updatedVideo) else { return }

        animator.addAnimations {
            let thumbnail = self.videoCell(at: indexPath)?.imageView.image
            
            self.delegate?.controller(
                self,
                didSelectAsset: updatedVideo,
                previewImage: thumbnail
            )
        }
    }
    
    // MARK: - Configuring
    
    func configureViews() {
        collectionView.collectionViewLayout = LibraryGridLayout { [weak self] newItemSize in
            self?.dataSource.imageOptions.size = newItemSize.scaledToScreen
        }
        
        collectionView.isPrefetchingEnabled = true
        collectionView.dataSource = dataSource
        collectionView.backgroundView = emptyView
        collectionView.collectionViewLayout.invalidateLayout()

        updateViews()
    }

    func updateViews() {
        guard isViewLoaded else { return }
        
        emptyView.type = dataSource.filter
        emptyView.isEmpty = dataSource.isEmpty && !dataSource.isUpdating
    }
    func configureDataSource() {
        dataSource.$album
            .combineLatest(
                dataSource.$isUpdating.removeDuplicates(),
                dataSource.$assetsChanged
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateViews()
            }.store(in: &bindings)

        dataSource.$assetsChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.collectionView.reloadData(animated: true)
            }.store(in: &bindings)
    }
    
    // MARK: Cell Handling
    
    func videoCell(at indexPath: IndexPath) -> VideoCell? {
        collectionView.cellForItem(at: indexPath) as? VideoCell
    }

    func cell(for video: PHAsset, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: VideoCell.className, for: indexPath) as? VideoCell else { fatalError("Wrong cell identifier or type.") }
        
        configure(cell: cell, for: video)
        return cell
    }

    func configure(cell: VideoCell, for video: PHAsset) {
        cell.durationLabel.text = durationFormatter.string(from: video.duration)
        cell.durationLabel.isHidden = video.isLivePhoto
        cell.livePhotoImageView.isHidden = !video.isLivePhoto
        cell.favoritedImageView.isHidden = !video.isFavorite
        cell.setGridContentMode(dataSource.gridMode, forAspectRatio: video.dimensions)
        
        loadThumbnail(for: cell, video: video)
    }

    func reconfigure(cellAt indexPath: IndexPath) {
        guard let cell = videoCell(at: indexPath),
              let video = dataSource.video(at: indexPath) else { return }
              
        configure(cell: cell, for: video)
    }

    func loadThumbnail(for cell: VideoCell, video: PHAsset) {
        cell.identifier = video.localIdentifier

        cell.imageRequest = dataSource.thumbnail(for: video) { image, _ in
            guard cell.identifier == video.localIdentifier,
                  let image = image else { return }

            cell.imageView.image = image
        }
    }

    func setGridMode(_ mode: LibraryGridMode, for cell: VideoCell, at indexPath: IndexPath) {
        guard let video = dataSource.video(at: indexPath) else { return }
        cell.setGridContentMode(mode, forAspectRatio: video.dimensions)

    }

    func setGridMode(_ mode: LibraryGridMode, animated: Bool) {
        guard animated else {
            collectionView.reloadData()
            return
        }
        
        let animations = {
            self.collectionView.indexPathsForVisibleItems.forEach { indexPath in
                guard let cell = self.videoCell(at: indexPath) else { return }
                self.setGridMode(mode, for: cell, at: indexPath)
            }
        }
        
        // Animate visible cells, then reload off-screen enqueued cells.
        UIView.animate(
            withDuration: LibraryGridViewController.contentModeAnimationDuration,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseInOut],
            animations: animations,
            completion: { _ in
                self.collectionView.reloadData()
            }
        )
    }
}
