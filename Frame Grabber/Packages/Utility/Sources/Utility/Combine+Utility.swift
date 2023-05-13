import Combine

extension Publisher where Self.Failure == Never {

    public func assignWeak<Root>(
        to keyPath: ReferenceWritableKeyPath<Root, Self.Output>,
        on object: Root?
    ) -> AnyCancellable where Root: AnyObject {
        sink { [weak object] value in
            object?[keyPath: keyPath] = value
        }
    }
}
