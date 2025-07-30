import Foundation
import CoreData
import Combine

@MainActor
class TransactionFormViewModel: ObservableObject {
    @Published var amount: String = ""
    @Published var note: String = ""
    @Published var date = Date()
    @Published var selectedCategory: Category?
    @Published var transactionType: TransactionType = .expense
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    enum TransactionType: String, CaseIterable {
        case income = "income"
        case expense = "expense"
        
        var displayName: String {
            switch self {
            case .income: return "Income"
            case .expense: return "Expense"
            }
        }
    }
    
    private let transactionRepository: TransactionRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private var existingTransaction: Transaction?
    
    var isEditMode: Bool {
        existingTransaction != nil
    }
    
    var navigationTitle: String {
        isEditMode ? "Edit Transaction" : "New Transaction"
    }
    
    var saveButtonTitle: String {
        isEditMode ? "Update" : "Add"
    }
    
    var amountValue: Double? {
        Double(amount.replacingOccurrences(of: ",", with: ""))
    }
    
    var isValidForm: Bool {
        guard let amountValue = amountValue,
              amountValue > 0 else { return false }
        return !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    init(
        transaction: Transaction? = nil,
        transactionRepository: TransactionRepositoryProtocol = TransactionRepository(),
        categoryRepository: CategoryRepositoryProtocol = CategoryRepository()
    ) {
        self.existingTransaction = transaction
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        
        if let transaction = transaction {
            self.amount = String(format: "%.2f", transaction.amount)
            self.note = transaction.note ?? ""
            self.date = transaction.date ?? Date()
            self.selectedCategory = transaction.category
            self.transactionType = transaction.type == "income" ? .income : .expense
        }
    }
    
    func loadCategories() async {
        do {
            let fetchedCategories = try await categoryRepository.fetchAll()
            await MainActor.run {
                self.categories = fetchedCategories
                if selectedCategory == nil && !categories.isEmpty {
                    selectedCategory = categories.first
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func saveTransaction() async -> Bool {
        guard let amountValue = amountValue else { return false }
        
        isLoading = true
        errorMessage = nil
        
        do {
            if let existingTransaction = existingTransaction {
                existingTransaction.amount = amountValue
                existingTransaction.note = note
                existingTransaction.date = date
                existingTransaction.category = selectedCategory
                existingTransaction.type = transactionType.rawValue
                
                try await transactionRepository.update(existingTransaction)
            } else {
                _ = try await transactionRepository.create(
                    amount: amountValue,
                    type: transactionType.rawValue,
                    date: date,
                    note: note,
                    category: selectedCategory
                )
            }
            
            await MainActor.run {
                self.isLoading = false
            }
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }
}