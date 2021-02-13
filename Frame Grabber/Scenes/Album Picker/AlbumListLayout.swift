import UIKit

/// The layout lays out its content against the layout margins of the collection view. Cells and
/// views can therefore pin to the superview's edges and not its layout margins.
class AlbumListLayout: UICollectionViewCompositionalLayout {
    
    private static let smartAlbumWidth: CGFloat = 140
    private static let fallbackLayoutMargins: CGFloat = 20

    init(sectionTypeProvider: @escaping (Int) -> (AlbumListSection.SectionType)) {
        super.init { index, environment in
            
            let sectionType = sectionTypeProvider(index)
            var section: NSCollectionLayoutSection!
            
            switch sectionType {
                    
            case .smartAlbum:
                let width = AlbumListLayout.smartAlbumWidth
                let estimatedHeight: CGFloat = width + 50
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(estimatedHeight))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(width), heightDimension: .estimated(estimatedHeight))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

                section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.interGroupSpacing = 12
                section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
                
            case .userAlbum:
                let estimatedHeight: CGFloat = 80

                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(estimatedHeight))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(estimatedHeight))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(estimatedHeight))
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)

                section = NSCollectionLayoutSection(group: group)
                section.boundarySupplementaryItems = [sectionHeader]
            }
            
            if #available(iOS 14.0, *) {
                section.contentInsetsReference = .layoutMargins
            } else {
                section.contentInsets.leading = AlbumListLayout.fallbackLayoutMargins
                section.contentInsets.trailing = AlbumListLayout.fallbackLayoutMargins
            }

            return section
        }
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard instantiation not supported.")
    }
}
