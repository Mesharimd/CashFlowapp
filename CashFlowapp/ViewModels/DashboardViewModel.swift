import Foundation
import CoreData
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var currentBalance: Double = 0.0
    @Published var recentTransactions: [Transaction] = []
    @Published var topCategories: [(category: Category, total: Double)] = []
    @Published var monthlyIncome: Double = 0.0
    @Published var monthlyExpense: Double = 0.0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let transactionRepository: TransactionRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        transactionRepository: TransactionRepositoryProtocol = TransactionRepository(),
        categoryRepository: CategoryRepositoryProtocol = CategoryRepository()
    ) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
    }
    
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let allTransactions = try await transactionRepository.fetchAll()
            
            let calendar = Calendar.current
            let now = Date()
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            
            let monthTransactions = try await transactionRepository.fetchByDateRange(
                from: startOfMonth,
                to: now
            )
            
            await MainActor.run {
                self.recentTransactions = Array(allTransactions.prefix(10))
                self.currentBalance = allTransactions.reduce(0) { sum, transaction in
                    sum + (transaction.type == "income" ? transaction.amount : -transaction.amount)
                }
                
                self.monthlyIncome = monthTransactions
                    .filter { $0.type == "income" }
                    .reduce(0) { $0 + $1.amount }
                
                self.monthlyExpense = monthTransactions
                    .filter { $0.type == "expense" }
                    .reduce(0) { $0 + $1.amount }
                
                self.calculateTopCategories(from: monthTransactions)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func calculateTopCategories(from transactions: [Transaction]) {
        var categoryTotals: [Category: Double] = [:]
        
        for transaction in transactions where transaction.type == "expense" {
            if let category = transaction.category {
                categoryTotals[category, default: 0] += transaction.amount
            }
        }
        
        topCategories = categoryTotals
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { ($0.key, $0.value) }
    }
}