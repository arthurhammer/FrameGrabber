import CoreMedia

extension CMSampleBuffer {

    /// A list of sample start times, one for each sample in the buffer.
    func outputSamplePresentationTimeStamps() throws -> [CMTime] {
        guard numSamples > 0 else { return [] }

        let timingInfos = try outputSampleTimingInfos()

        // A single timing info can apply to multiple samples. In that case, we need to
        // manually calculate the presentation times. For details, see `CMSampleTimingInfo`.
        let infoAppliesToMultipleSamples = (numSamples > 1) && (timingInfos.count == 1)

        if infoAppliesToMultipleSamples,
            let start = timingInfos.first {

            return stride(from: 0, to: numSamples, by: 1).map { index in
                let offset = CMTimeMultiply(start.duration, multiplier: Int32(index))
                return start.presentationTimeStamp + offset
            }
        }

        return timingInfos.map { $0.presentationTimeStamp }
    }
}
