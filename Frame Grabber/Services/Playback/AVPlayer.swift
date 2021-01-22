import AVFoundation
import Combine

extension AVPlayer {

    /// A publisher that publishes the player's changing time periodically (wrapping around
    /// `addPeriodicTimeObserver`).
    func periodicTimePublisher(forInterval interval: CMTime) -> AnyPublisher<CMTime, Never> {
        
        let periodicPublisher = PassthroughSubject<CMTime, Never>()

        let observer = addPeriodicTimeObserver(forInterval: interval, queue: nil) {
            [weak periodicPublisher] in
            periodicPublisher?.send($0)
        }

        let cancellingPublisher = periodicPublisher.handleEvents(receiveCancel: { [weak self] in
            self?.removeTimeObserver(observer)
        })

        return cancellingPublisher.eraseToAnyPublisher()
    }
}

extension AVPlayer {

    /// The combined status of the player and its current player item.
    typealias PlayerAndItemStatus = Status

    /// A publisher that publishes the combined player's and its current item's status whenever
    /// either changes.
    func playerAndItemStatusPublisher() -> AnyPublisher<PlayerAndItemStatus, Never> {
        publisher(for: \.status)
            .combineLatest(
                publisher(for: \.currentItem?.status).replaceNil(with: .unknown)
            )
            .map(combinedStatus)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

private func combinedStatus(
    for status: (AVPlayer.Status, AVPlayerItem.Status)
) -> AVPlayer.PlayerAndItemStatus {
    
    switch status {
    case (.failed, _), (_, .failed): return .failed
    case (.readyToPlay, .readyToPlay): return .readyToPlay
    case (.unknown, _), (_, .unknown): return .unknown
    @unknown default: return .unknown
    }
}
