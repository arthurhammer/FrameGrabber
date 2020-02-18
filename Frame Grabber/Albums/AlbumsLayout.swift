import UIKit

class AlbumsLayout: UICollectionViewCompositionalLayout {

    init(didUpdateUserAlbumItemSizeHandler: ((CGSize) -> ())? = nil) {
        super.init { index, environment in

            guard let type = AlbumsCollectionViewDataSource.SectionType(index) else { fatalError("Unknown section type.") }

            switch type {

            case .smartAlbum:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(46))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)

                return section

            case .userAlbum:
                let itemHeight: CGFloat = 80

                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(itemHeight))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44))
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)

                let section = NSCollectionLayoutSection(group: group)
                section.boundarySupplementaryItems = [sectionHeader]

                didUpdateUserAlbumItemSizeHandler?(CGSize(width: itemHeight, height: itemHeight))
                return section
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
