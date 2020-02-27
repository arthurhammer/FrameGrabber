import UIKit
import Combine

class AlbumsSearcher: NSObject {

    var albums = [AnyAlbum]() {
        didSet { updateFilter() }
    }

    private(set) var filtered = [AnyAlbum]()
    private(set) var searchTerm: String?

    private let updateHandler: ([AnyAlbum]) -> ()
    private let searchTermPublisher = PassthroughSubject<String?, Never>()
    private var searchTermObserver: AnyCancellable?

    init(albums: [AnyAlbum] = [], updateHandler: @escaping ([AnyAlbum]) -> ()) {
        self.albums = albums
        self.updateHandler = updateHandler

        super.init()

        searchTermObserver = searchTermPublisher
            .throttle(for: 0.3, scheduler: DispatchQueue.main, latest: true)
            .map { $0?.trimmedOrNil }
            .removeDuplicates()
            .sink { [weak self] in
                self?.searchTerm = $0
                self?.updateFilter()
            }
    }

    func search(for searchTerm: String?) {
        searchTermPublisher.send(searchTerm)
    }

    private func updateFilter() {
        filtered = filteredAlbums(albums, by: searchTerm)
        updateHandler(filtered)
    }

    private func filteredAlbums(_ albums: [AnyAlbum], by searchTerm: String?) -> [AnyAlbum] {
        guard let searchTerm = searchTerm?.trimmedOrNil else { return albums }

        return albums.filter {
            $0.title?.range(of: searchTerm, options: [.diacriticInsensitive, .caseInsensitive]) != nil
        }
    }
}

extension AlbumsSearcher: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        search(for: searchController.searchBar.text)
    }
}
