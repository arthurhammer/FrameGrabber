import AVFoundation
import Combine

extension AVPlayer {

    static let defaultPeriodicTimeInterval: CMTime = CMTime(seconds: 1/30.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

    func periodicTimePublisher(forInterval interval: CMTime = AVPlayer.defaultPeriodicTimeInterval) -> AnyPublisher<CMTime, Never> {
        let publisher = PassthroughSubject<CMTime, Never>()

        let observer = addPeriodicTimeObserver(forInterval: interval, queue: nil) { [weak publisher] in
            publisher?.send($0)
        }

        let cancellingPublisher = publisher.handleEvents(receiveCancel: { [weak self] in
            self?.removeTimeObserver(observer)
        })

        return cancellingPublisher.eraseToAnyPublisher()
    }
}

extension AVPlayer {

    typealias PlayerAndItemStatus = Status

    func playerAndItemStatusPublisher() -> AnyPublisher<PlayerAndItemStatus, Never> {
        publisher(for: \.status)
            .combineLatest(publisher(for: \.currentItem?.status).replaceNil(with: .unknown))
            .map { status in
                switch status {
                case (.failed, _), (_, .failed): return .failed
                case (.readyToPlay, .readyToPlay): return .readyToPlay
                case (.unknown, _), (_, .unknown): return .unknown
                @unknown default: return .unknown
                }
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
