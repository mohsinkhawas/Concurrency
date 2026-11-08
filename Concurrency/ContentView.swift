import SwiftUI

struct ContentView: View {
    @State private var session = DemoSession()

    var body: some View {
        NavigationSplitView {
            SidebarList(session: session)
                .navigationSplitViewColumnWidth(min: 240, ideal: 300, max: 360)
        } detail: {
            TechnologyDetailView(session: session)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 1100, minHeight: 740)
    }
}

#Preview {
    ContentView()
}
