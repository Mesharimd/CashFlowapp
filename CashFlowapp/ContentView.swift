import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            TransactionListView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
            
            CategoryManagerView()
                .tabItem {
                    Label("Categories", systemImage: "tag")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, DataController.preview.container.viewContext)
}
