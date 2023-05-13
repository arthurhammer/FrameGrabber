@preconcurrency import AVFoundation
import CoreLocation

extension AVAsset {
    
    func loadMetadata() async throws -> VideoMetadata {
        // (Preload tracks at the same time.)
        let (duration, creationDate, commonMetadataItems, _) = try await load(.duration, .creationDate, .commonMetadata, .tracks)
        
        async let creationDateValues = creationDate?.load(.dateValue, .stringValue)
        async let trackMetadata = loadTrackMetadata()
        async let commonMetadata = loadCommonMetadata(for: commonMetadataItems)
        
        return try await .init(
            duration: duration,
            creationDate: creationDateValues?.0,
            creationDateString: creationDateValues?.1,
            track: trackMetadata,
            common: commonMetadata
        )
    }
    
    private func loadTrackMetadata() async throws -> VideoMetadata.Track? {
        guard let track = try await loadTracks(withMediaType: .video).first else {
            return nil
        }
        
        let (
            naturalSize,
            preferredTransform,
            nominalFrameRate,
            estimatedDataRate,
            totalSampleDataLength,
            formatDescriptions
        ) = try await track.load(
            .naturalSize,
            .preferredTransform,
            .nominalFrameRate,
            .estimatedDataRate,
            .totalSampleDataLength,
            .formatDescriptions
        )
        
        return .init(
            trackID: track.trackID,
            naturalSize: naturalSize,
            preferredTransform: preferredTransform,
            nominalFrameRate: nominalFrameRate,
            estimatedDataRate: estimatedDataRate,
            totalSampleDataLength: totalSampleDataLength,
            formatDescriptions: formatDescriptions
        )
    }
    
    private func loadCommonMetadata(for commonMetadata: [AVMetadataItem]) async throws -> VideoMetadata.Common {
        async let make = stringValue(for: .commonIdentifierMake, in: commonMetadata)
        async let model = stringValue(for: .commonIdentifierModel, in: commonMetadata)
        async let software = stringValue(for: .commonIdentifierSoftware, in: commonMetadata)
        async let location = stringValue(for: .commonIdentifierLocation, in: commonMetadata)
        
        let locationParser = ISO6709LocationParser()
        
        return try await .init(
            make: make,
            model: model,
            software: software,
            locationString: location,
            location: location.flatMap(locationParser.location)
        )
    }
    
    private func stringValue(for identifier: AVMetadataIdentifier, in metadata: [AVMetadataItem]) async throws -> String? {
        let items = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: identifier)
        return try await items.first?.load(.stringValue)
    }
}
