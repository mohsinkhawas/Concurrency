import SwiftUI

struct TechnologyDetailView: View {
    @Bindable var session: DemoSession

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                Group {
                    if session.detailTab == .overview {
                        overviewContent
                    } else {
                        CodeDocumentationView(technology: session.technology)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(session.technology.title)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Section", selection: $session.detailTab) {
                    ForEach(DetailTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: session.technology.symbolName)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(session.technology.tint)
                .frame(width: 48, height: 48)
                .background(session.technology.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(session.technology.title)
                        .font(.title2.weight(.semibold))
                    StyleTag(text: session.technology.executionStyle, tint: session.technology.tint)
                    StyleTag(text: session.technology.shortTitle, tint: .secondary)
                }
                Text(session.technology.subtitle)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            if session.detailTab == .overview {
                StatusPill(status: session.status)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var overviewContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            DemoSection(session: session)
            ImageCanvas(image: session.image, status: session.status, error: session.lastError)
                .frame(minHeight: 360)
        }
    }
}

struct CodeDocumentationView: View {
    let technology: ConcurrencyTechnology

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GroupBox("Architectural overview") {
                Text(technology.architecturalOverview)
                    .font(.callout)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
            }
            HStack(alignment: .top, spacing: 12) {
                GroupBox("Memory model") {
                    Text(technology.memoryModel)
                        .font(.callout)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 2)
                }
                GroupBox("Safety guarantees") {
                    Text(technology.safetyGuarantees)
                        .font(.callout)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 2)
                }
            }
            HStack(alignment: .top, spacing: 12) {
                GroupBox("Benefits") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(technology.benefits, id: \.self) { item in
                            Label(item, systemImage: "checkmark.circle")
                                .foregroundStyle(.green)
                                .font(.callout)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
                }
                GroupBox("Drawbacks") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(technology.drawbacks, id: \.self) { item in
                            Label(item, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                                .font(.callout)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
                }
            }
            GroupBox("Cancellation") {
                Text(technology.cancellationNotes)
                    .font(.callout)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
            }
            GroupBox("Image download boilerplate") {
                Text(technology.codePreview)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
        }
    }
}
