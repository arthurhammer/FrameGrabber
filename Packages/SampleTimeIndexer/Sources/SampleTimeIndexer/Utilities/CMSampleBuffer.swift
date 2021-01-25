import CoreMedia

extension CMSampleBuffer {

    /// Returns individual sample timing infos, one for each sample in the buffer.
    ///
    /// In comparison to `outputSampleTimingInfos`, this function creates individual timing infos if
    /// a single timing info describes all samples in the buffer.
    ///
    /// A single timing info can describe every individual sample in a CMSampleBuffer, if the
    /// samples all have the same duration and are in presentation order with no gaps.
    ///
    /// See `CMSampleTimingInfo` for details.
    ///
    /// - Note: The timing infos are not guaranteed to be ordered by their presentation time.
    func individualOutputSampleTimingInfos() throws -> [CMSampleTimingInfo] {
        guard numSamples > 0 else { return [] }

        let sampleTimes = try outputSampleTimingInfos()
        let singleInfoDescribesAllSamples = (sampleTimes.count == 1) && (numSamples > 1)

        if singleInfoDescribesAllSamples,
            let reference = sampleTimes.first {

            return spacedSampleTimes(from: reference, count: numSamples)
        }

        return sampleTimes
    }
    
    private func spacedSampleTimes(
        from reference: CMSampleTimingInfo,
        count: Int
    ) -> [CMSampleTimingInfo] {
        
        (0..<count).map { index in
            let offset = CMTimeMultiply(reference.duration, multiplier: Int32(index))
            let time = reference.presentationTimeStamp + offset
            
            return CMSampleTimingInfo(
                duration: reference.duration,
                presentationTimeStamp: time,
                decodeTimeStamp: .invalid  // See docs.
            )
        }
    }
}
