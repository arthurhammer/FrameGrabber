import UIKit

/// The collection view layout used by the Album Picker.
///
/// The layout lays out its content against the layout margins of the collection view. Cells and
/// views can therefore pin to the superview's edges and not its layout margins.
class AlbumListLayout: UICollectionViewCompositionalLayout {
    
    enum SectionType {
        case horizontal
        case vertical
    }
    
    private static let horizontalAlbumWidth: CGFloat = 140
    private static let horizontalSpacing: CGFloat = 12

    init(sectionTypeProvider: @escaping (Int) -> (SectionType)) {
        super.init { index, environment in
            
            let section: NSCollectionLayoutSection
            
            switch sectionTypeProvider(index) {
            case .horizontal:
                section = AlbumListLayout.makeHorizontalSection()
            case .vertical:
                section = AlbumListLayout.makeVerticalSection()
            }
            
            section.contentInsetsReference = .layoutMargins

            return section
        }
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard instantiation not supported.")
    }
    
    private static func makeHorizontalSection() -> NSCollectionLayoutSection {
        let width = horizontalAlbumWidth
        let estimatedHeight: CGFloat = width + 50
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(estimatedHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(width), heightDimension: .estimated(estimatedHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        
        let spacing = horizontalSpacing
        section.interGroupSpacing = spacing
        section.contentInsets = NSDirectionalEdgeInsets(top: spacing, leading: 0, bottom: spacing, trailing: 0)
        
        return section
    }
        
    private static func makeVerticalSection() -> NSCollectionLayoutSection {
        let estimatedHeight: CGFloat = 80

        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(estimatedHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(estimatedHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(estimatedHeight))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)

        let section = NSCollectionLayoutSection(group: group)
        section.boundarySupplementaryItems = [sectionHeader]
        
        return section
    }
}
