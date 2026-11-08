import SwiftUI

struct ImageCanvas: View {
    let image: NSImage?
    let status: ExecutionStatus
    let error: String?

    var body: some View {
        GroupBox("Output · NSImage") {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.background)

                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .padding(8)
                } else {
                    ContentUnavailableView {
                        Label(emptyTitle, systemImage: emptySymbol)
                    } description: {
                        Text(emptyDescription)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 4)
        }
    }

    private var emptyTitle: String {
        switch status {
        case .failed: return "Download failed"
        case .cancelled: return "Cancelled"
        case .dispatched, .downloading, .processing: return "Downloading"
        default: return "No image"
        }
    }

    private var emptySymbol: String {
        switch status {
        case .failed: return "exclamationmark.triangle"
        case .cancelled: return "xmark.circle"
        case .dispatched, .downloading, .processing: return "arrow.down.circle"
        default: return "photo"
        }
    }

    private var emptyDescription: String {
        if let error, status == .failed { return error }
        switch status {
        case .cancelled: return "Cancellation prevented a main-thread publish."
        case .dispatched, .downloading, .processing: return "Work is running off the main thread."
        default: return "Download a remote image to render it on the main actor."
        }
    }
}
