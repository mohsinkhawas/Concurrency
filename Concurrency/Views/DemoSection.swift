import SwiftUI

struct DemoSection: View {
    @Bindable var session: DemoSession

    var body: some View {
        GroupBox("Interactive demo · image downloader") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Picker("Preset", selection: $session.selectedPresetID) {
                        ForEach(SampleImage.presets) { sample in
                            Text(sample.title).tag(sample.id)
                        }
                    }
                    .frame(maxWidth: 280)

                    TextField("Custom image URL", text: $session.customURL, prompt: Text("https://…"))
                        .textFieldStyle(.roundedBorder)

                    Button("Download Image") {
                        session.download()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(session.isRunning)

                    Button("Cancel") {
                        session.cancel()
                    }
                    .disabled(!session.isRunning)
                }

                TelemetryBar(session: session)
            }
            .padding(.top, 4)
        }
    }
}

struct TelemetryBar: View {
    @Bindable var session: DemoSession

    var body: some View {
        HStack(spacing: 12) {
            TelemetryCard(title: "Status", value: session.status.title, detail: session.isRunning ? "In flight" : "Settled")
            TelemetryCard(
                title: "Thread",
                value: session.executionThread.map { $0.isMain ? "Main" : "Background" } ?? "—",
                detail: session.executionThread.map { "\($0.name) · id \($0.id)" } ?? "Waiting for dispatch"
            )
            TelemetryCard(
                title: "Elapsed",
                value: String(format: "%.0f ms", session.elapsedMilliseconds),
                detail: session.byteCount > 0 ? ByteCountFormatter.string(fromByteCount: Int64(session.byteCount), countStyle: .file) : "No payload"
            )
            TelemetryCard(
                title: "Process",
                value: session.telemetry.memoryLabel,
                detail: "\(session.telemetry.threadCount) threads · Δ \(deltaThreads) thr"
            )
        }
    }

    private var deltaThreads: Int {
        session.telemetry.threadCount - session.baselineTelemetry.threadCount
    }
}

struct TelemetryCard: View {
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
                .lineLimit(1)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
