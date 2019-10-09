import UIKit
import CoreMedia

protocol SelectedFramesViewControllerDelegate: class {
    func controller(_ controller: SelectedFramesViewController, didSelectFrameAt time: CMTime)
}

class SelectedFramesViewController: UICollectionViewController {

    weak var delegate: SelectedFramesViewControllerDelegate?

    var dataSource: SelectedFramesDataSource? {
        didSet {
            updateThumbnailSize()
            collectionView.reloadData()
        }
    }

    var frames: [CMTime] {
        dataSource?.frames.map { $0.definingTime } ?? []
    }

    let selectionBorderWidth: CGFloat = 3

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateThumbnailSize()
    }

    var isGeneratingFrames: Bool {
        dataSource?.isGeneratingFrames == true
    }

    func insertFrame(for time: CMTime, completion: @escaping (SelectedFramesDataSource.InsertionResult) -> ()) {
        dataSource?.generateAndInsertFrame(for: time) { [weak self] result in
            let indexPath = IndexPath(item: result.index, section: 0)

            if case .inserted = result {
                self?.collectionView.insertItems(at: [indexPath])
            }

            self?.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            completion(result)
        }
    }

    @IBAction private func removeFrame(_ sender: UIButton) {
        let buttonLocation = sender.convert(CGPoint.zero, to: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: buttonLocation) else { return }
        dataSource?.removeFrame(at: indexPath.item)
        collectionView.deleteItems(at: [indexPath])
    }

    func selectFrame(at index: Int) {
        let indexPath = IndexPath(item: index, section: 0)
        let isAlreadySelected = collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false

        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        UISelectionFeedbackGenerator().selectionChanged()

        if isAlreadySelected {
            collectionView.cellForItem(at: indexPath)?.bounce()
        }
    }

    func clearSelection() {
        collectionView.selectItem(at: nil, animated: true, scrollPosition: [])
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateThumbnailSize()
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let frame = dataSource?.frames[indexPath.item] else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        delegate?.controller(self, didSelectFrameAt: frame.definingTime)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dataSource?.frames.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FrameCell.name, for: indexPath) as? FrameCell else { fatalError("Wrong cell id or type") }
        cell.imageView.image = dataSource?.frames[indexPath.item].image
        cell.selectionBorderWidth = selectionBorderWidth
        return cell
    }

    private func configureViews() {
        collectionView.applyOverlayShadow()
        // Remove margin left for the selection view.
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.minimumLineSpacing = -selectionBorderWidth
    }

    private func updateThumbnailSize() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }

        let squares = CGSize(width: view.bounds.height, height: view.bounds.height)
        layout.itemSize = squares
        dataSource?.imageSize = squares.scaledToScreen
    }
}
