import Foundation

@MainActor
protocol DownloadEngine: AnyObject {
    func start(url: URL, sink: DownloadSink)
    func cancel()
}
