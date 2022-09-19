import Photos
import Combine

extension PHAssetResourceManager {

    /// A variant of `writeData` that can be cancelled.
    ///
    /// The data is loaded fully in memory and then written to disk.
    ///
    /// When cancelled, the completion handler is called with an `CocoaError.userCancelled`
    /// error. In that case, the manager attempts to delete the resource if it was already
    /// written. It is not guaranteed that the resource is deleted in all cases.
    ///
    /// - Parameters:
    ///   - handlerQueue: The queue to call handlers on, default is `main`.
    ///
    /// - Returns: An object that cancels the request if released.
    func requestAndWriteData(
        for resource: PHAssetResource,
        toFile fileUrl: URL,
        options: PHAssetResourceRequestOptions = .init(),
        fileManager: FileManager = .default,
        handlerQueue: DispatchQueue = .main,
        progressHandler: ((Double) -> ())? = nil,
        completionHandler: @escaping (Result<URL, Error>) -> Void
    ) -> Cancellable {

        options.progressHandler = { progress in
            handlerQueue.async {
                progressHandler?(progress)
            }
        }

        let completion = { result in
            handlerQueue.async {
                completionHandler(result)
            }
        }

        var data = Data()
        var didCancel = false
        let accessQueue = DispatchQueue(label: "", qos: .userInitiated)

        let id = requestData(for: resource, options: options, dataReceivedHandler: {

            data.append($0)

        }, completionHandler: { error in

            if let error {
                completion(.failure(error))
                return
            }

            do {
                try data.write(to: fileUrl)
            } catch {
                completion(.failure(error))
            }

            // Handle cancelling between the data request succeeding and the data being written to
            // disk. Later cancellations are ignored.
            let didCancel = accessQueue.sync { didCancel }

            if didCancel {
                try? fileManager.removeItem(at: fileUrl)
                completion(.failure(CocoaError(.userCancelled)))
            } else {
                completion(.success(fileUrl))
            }
        })

        return AnyCancellable {
            accessQueue.sync { didCancel = true }
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
