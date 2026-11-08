import AppKit
import Combine
import Foundation

final class CombineDownloadEngine: DownloadEngine {
    private var cancellables = Set<AnyCancellable>()

    func start(url: URL, sink: DownloadSink) {
        cancel()
        let sink = sink
        sink.status(.dispatched)
        sink.log("URLSession.shared.dataTaskPublisher(for:) subscribed")

        URLSession.shared.dataTaskPublisher(for: url)
            .handleEvents(
                receiveSubscription: { _ in
                    let snap = ThreadSnapshot.capture()
                    sink.status(.downloading, thread: snap)
                    sink.log("Combine subscription active — dataTask started", thread: snap)
                },
                receiveCancel: {
                    let snap = ThreadSnapshot.capture()
                    sink.log("AnyCancellable.cancel() propagated to URLSession", thread: snap)
                    sink.cancelled(thread: snap)
                }
            )
            .map(\.data)
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .tryMap { data -> Data in
                let snap = ThreadSnapshot.capture()
                sink.status(.processing, thread: snap)
                sink.log("Operator pipeline mapped \(data.count) bytes on a global queue", thread: snap)
                guard NSImage(data: data) != nil else {
                    throw URLError(.cannotDecodeContentData)
                }
                return data
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
            .sink(
                receiveCompletion: { completion in
                    let snap = ThreadSnapshot.capture()
                    if case .failure(let error) = completion {
                        if (error as? URLError)?.code == .cancelled {
                            sink.cancelled(thread: snap)
                        } else {
                            sink.fail(error.localizedDescription, thread: snap)
                        }
                    }
                },
                receiveValue: { data in
                    let snap = ThreadSnapshot.capture()
                    sink.log("receive(on: DispatchQueue.main) — rendering UI", thread: snap)
                    sink.complete(data, thread: snap)
                }
            )
            .store(in: &cancellables)
    }

    func cancel() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
