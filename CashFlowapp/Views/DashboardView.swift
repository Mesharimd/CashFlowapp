import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedTimeRange = TimeRange.week
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    balanceCard
                    incomeExpenseCard
                    chartCard
                    topCategoriesCard
                    recentTransactionsCard
                }
                .padding()
            }
            .background(Theme.backgroundColor)
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.loadDashboardData()
            }
            .task {
                await viewModel.loadDashboardData()
            }
        }
    }
    
    private var balanceCard: some View {
        VStack(spacing: 8) {
            Text("Current Balance")
                .font(Theme.subheadline)
                .foregroundColor(Theme.secondaryTextColor)
            
            Text(formatCurrency(viewModel.currentBalance))
                .font(Theme.largeTitle)
                .foregroundColor(viewModel.currentBalance >= 0 ? Theme.successColor : Theme.dangerColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.secondaryBackgroundColor)
        .cornerRadius(Theme.cornerRadius)
    }
    
    private var incomeExpenseCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Label("Income", systemImage: "arrow.down.circle.fill")
                    .font(Theme.caption)
                    .foregroundColor(Theme.successColor)
                
                Text(formatCurrency(viewModel.monthlyIncome))
                    .font(Theme.title3)
                    .foregroundColor(Theme.textColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            VStack(alignment: .trailing, spacing: 4) {
                Label("Expense", systemImage: "arrow.up.circle.fill")
                    .font(Theme.caption)
                    .foregroundColor(Theme.dangerColor)
                
                Text(formatCurrency(viewModel.monthlyExpense))
                    .font(Theme.title3)
                    .foregroundColor(Theme.textColor)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(Theme.secondaryBackgroundColor)
        .cornerRadius(Theme.cornerRadius)
    }
    
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cash Flow Trend")
                    .font(Theme.headline)
                
                Spacer()
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            Chart {
                
            }
            .frame(height: 200)
            .overlay(
                Text("Chart Coming Soon")
                    .font(Theme.caption)
                    .foregroundColor(Theme.secondaryTextColor)
            )
        }
        .padding()
        .background(Theme.secondaryBackgroundColor)
        .cornerRadius(Theme.cornerRadius)
    }
    
    private var topCategoriesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Categories")
                .font(Theme.headline)
            
            if viewModel.topCategories.isEmpty {
                Text("No expenses this month")
                    .font(Theme.subheadline)
                    .foregroundColor(Theme.secondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
            } else {
                ForEach(viewModel.topCategories, id: \.category.id) { item in
                    HStack {
                        Image(systemName: item.category.icon ?? "tag.fill")
                            .foregroundColor(Color(hex: item.category.color ?? "#808080"))
                            .frame(width: 30)
                        
                        Text(item.category.name ?? "Unknown")
                            .font(Theme.body)
                        
                        Spacer()
                        
                        Text(formatCurrency(item.total))
                            .font(Theme.callout)
                            .foregroundColor(Theme.secondaryTextColor)
                    }
                }
            }
        }
        .padding()
        .background(Theme.secondaryBackgroundColor)
        .cornerRadius(Theme.cornerRadius)
    }
    
    private var recentTransactionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(Theme.headline)
                
                Spacer()
                
                NavigationLink(destination: TransactionListView()) {
                    Text("See All")
                        .font(Theme.caption)
                        .foregroundColor(Theme.primaryColor)
                }
            }
            
            if viewModel.recentTransactions.isEmpty {
                Text("No transactions yet")
                    .font(Theme.subheadline)
                    .foregroundColor(Theme.secondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
            } else {
                ForEach(viewModel.recentTransactions.prefix(5)) { transaction in
                    TransactionRowView(transaction: transaction)
                }
            }
        }
        .padding()
        .background(Theme.secondaryBackgroundColor)
        .cornerRadius(Theme.cornerRadius)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            Image(systemName: transaction.category?.icon ?? "tag.fill")
                .foregroundColor(Color(hex: transaction.category?.color ?? "#808080"))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.note ?? "Transaction")
                    .font(Theme.body)
                    .lineLimit(1)
                
                Text(transaction.category?.name ?? "Uncategorized")
                    .font(Theme.caption)
                    .foregroundColor(Theme.secondaryTextColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(transaction.amount))
                    .font(Theme.callout)
                    .foregroundColor(transaction.type == "income" ? Theme.successColor : Theme.textColor)
                
                Text(formatDate(transaction.date))
                    .font(Theme.caption)
                    .foregroundColor(Theme.secondaryTextColor)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
        return amount >= 0 ? formattedAmount : formattedAmount
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, DataController.preview.container.viewContext)
}