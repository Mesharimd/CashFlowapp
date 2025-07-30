import SwiftUI

struct TransactionListView: View {
    @StateObject private var viewModel = TransactionListViewModel()
    @State private var showingAddTransaction = false
    @State private var selectedTransaction: Transaction?
    
    var body: some View {
        NavigationView {
            VStack {
                searchAndFilterBar
                
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredTransactions.isEmpty {
                    emptyStateView
                } else {
                    transactionsList
                }
            }
            .background(Theme.backgroundColor)
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTransaction = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Theme.primaryColor)
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                TransactionFormView()
            }
            .sheet(item: $selectedTransaction) { transaction in
                TransactionFormView(transaction: transaction)
            }
            .task {
                await viewModel.loadTransactions()
            }
        }
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.secondaryTextColor)
                
                TextField("Search transactions...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.secondaryTextColor)
                    }
                }
            }
            .padding(12)
            .background(Theme.secondaryBackgroundColor)
            .cornerRadius(Theme.cornerRadius)
            
            Picker("Filter", selection: $viewModel.selectedFilter) {
                ForEach(TransactionListViewModel.TransactionFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Theme.secondaryTextColor)
            
            Text("No transactions found")
                .font(Theme.headline)
                .foregroundColor(Theme.textColor)
            
            Text("Add your first transaction to get started")
                .font(Theme.subheadline)
                .foregroundColor(Theme.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            Button(action: { showingAddTransaction = true }) {
                Label("Add Transaction", systemImage: "plus.circle")
                    .font(Theme.callout)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Theme.primaryColor)
                    .cornerRadius(Theme.cornerRadius)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var transactionsList: some View {
        List {
            if !viewModel.searchText.isEmpty {
                Section {
                    Text("\(viewModel.filteredTransactions.count) results")
                        .font(Theme.caption)
                        .foregroundColor(Theme.secondaryTextColor)
                }
            }
            
            ForEach(groupedTransactions, id: \.key) { date, transactions in
                Section(header: Text(formatSectionDate(date))) {
                    ForEach(transactions) { transaction in
                        TransactionListRow(transaction: transaction)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTransaction = transaction
                            }
                    }
                    .onDelete { offsets in
                        Task {
                            let transactionsToDelete = offsets.map { transactions[$0] }
                            for transaction in transactionsToDelete {
                                await viewModel.deleteTransaction(transaction)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            await viewModel.loadTransactions()
        }
    }
    
    private var groupedTransactions: [(key: Date, value: [Transaction])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: viewModel.filteredTransactions) { transaction in
            calendar.startOfDay(for: transaction.date ?? Date())
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}

struct TransactionListRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: transaction.category?.color ?? "#808080"))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: transaction.category?.icon ?? "tag.fill")
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.note ?? "Transaction")
                    .font(Theme.body)
                    .lineLimit(1)
                
                Text(transaction.category?.name ?? "Uncategorized")
                    .font(Theme.caption)
                    .foregroundColor(Theme.secondaryTextColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(transaction.amount))
                    .font(Theme.callout)
                    .fontWeight(.medium)
                    .foregroundColor(transaction.type == "income" ? Theme.successColor : Theme.textColor)
                
                Text(formatTime(transaction.date))
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
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    TransactionListView()
        .environment(\.managedObjectContext, DataController.preview.container.viewContext)
}