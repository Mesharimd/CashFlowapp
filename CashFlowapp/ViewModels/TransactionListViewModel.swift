import Foundation
import CoreData
import Combine

@MainActor
class TransactionListViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFilter: TransactionFilter = .all
    
    enum TransactionFilter: String, CaseIterable {
        case all = "All"
        case income = "Income"
        case expense = "Expense"
        
        var predicate: NSPredicate? {
            switch self {
            case .all:
                return nil
            case .income:
                return NSPredicate(format: "type == %@", "income")
            case .expense:
                return NSPredicate(format: "type == %@", "expense")
            }
        }
    }
    
    private let transactionRepository: TransactionRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    var filteredTransactions: [Transaction] {
        if searchText.isEmpty {
            return transactions
        } else {
            return transactions.filter { transaction in
                transaction.note?.localizedCaseInsensitiveContains(searchText) ?? false ||
                transaction.category?.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    var totalBalance: Double {
        transactions.reduce(0) { sum, transaction in
            sum + (transaction.type == "income" ? transaction.amount : -transaction.amount)
        }
    }
    
    init(transactionRepository: TransactionRepositoryProtocol = TransactionRepository()) {
        self.transactionRepository = transactionRepository
        setupBindings()
    }
    
    private func setupBindings() {
        $selectedFilter
            .sink { [weak self] _ in
                Task {
                    await self?.loadTransactions()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadTransactions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
            let fetchedTransactions = try await transactionRepository.fetch(
                predicate: selectedFilter.predicate,
                sortDescriptors: sortDescriptors
            )
            
            await MainActor.run {
                self.transactions = fetchedTransactions
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) async {
        do {
            try await transactionRepository.delete(transaction)
            await loadTransactions()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteTransactions(at offsets: IndexSet) async {
        for index in offsets {
            if index < filteredTransactions.count {
                await deleteTransaction(filteredTransactions[index])
            }
        }
    }
}