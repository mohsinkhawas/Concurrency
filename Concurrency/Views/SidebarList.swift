import SwiftUI

struct SidebarList: View {
    @Bindable var session: DemoSession

    var body: some View {
        List(ConcurrencyTechnology.allCases, selection: $session.technology) { technology in
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(technology.title)
                            .font(.body.weight(.semibold))
                        StyleTag(text: technology.executionStyle, tint: technology.tint)
                    }
                    Text(technology.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } icon: {
                Image(systemName: technology.symbolName)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(technology.tint)
            }
            .tag(technology)
            .padding(.vertical, 4)
        }
        .listStyle(.sidebar)
        .navigationTitle("Concurrency")
    }
}
