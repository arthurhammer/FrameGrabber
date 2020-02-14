import Photos
import Combine

extension PHAssetResourceManager {

    /// Releasing the returned object cancels the request. In that case, the completion
    /// handler is called with an `CocoaError.userCancelled` error.
    /// Handlers are called asynchronously on the main thread.
    func requestAndWriteData(for resource: PHAssetResource, toFile fileURL: URL, options: PHAssetResourceRequestOptions?, fileManager: FileManager = .default, progressHandler: ((Double) -> ())? = nil, completionHandler: @escaping (Error?) -> Void) -> Cancellable {
        let options = options ?? .init()

        options.progressHandler = { progress in
            DispatchQueue.main.async {
                progressHandler?(progress)
            }
        }

        let finish = { error in
            DispatchQueue.main.async {
                completionHandler(error)
            }
        }

        var data = Data()
        var didCancel = false

        let id = requestData(for: resource, options: options, dataReceivedHandler: { chunk in
            data.append(chunk)
        }, completionHandler: { error in

            guard error == nil else {
                finish(error)
                return
            }

            do {
                try data.write(to: fileURL)

                // Handle caller cancelling between the data request succeeding and the
                // data being written to disk (there's still a race condition).
                if didCancel {
                    try fileManager.removeItem(at: fileURL)
                    finish(CocoaError(.userCancelled))
                } else {
                    finish(nil)
                }
            } catch let error {
                finish(error)
            }
        })

        return AnyCancellable {
            didCancel = true
            self.cancelDataRequest(id)
        }
    }
}

extension PHAssetResource {
    static func videoResource(forLivePhoto livePhoto: PHAsset) -> PHAssetResource? {
        let resources = assetResources(for: livePhoto)
        return resources.first {  $0.type == .fullSizePairedVideo }
            ?? resources.first {  $0.type == .pairedVideo }
    }
}

extension PHAssetResourceRequestOptions {
    /// Allowed network access.
    static func `default`() -> PHAssetResourceRequestOptions {
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        return options
    }
}

extension Error {
    var isCancelled: Bool {
        let error = self as NSError
        return (error.domain == CocoaError.errorDomain) && (error.code == CocoaError.userCancelled.rawValue)
    }
}
