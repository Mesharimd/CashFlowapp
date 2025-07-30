import CoreData
import Foundation

protocol TransactionRepositoryProtocol {
    func fetchAll() async throws -> [Transaction]
    func fetch(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]) async throws -> [Transaction]
    func create(amount: Double, type: String, date: Date, note: String?, category: Category?) async throws -> Transaction
    func update(_ transaction: Transaction) async throws
    func delete(_ transaction: Transaction) async throws
    func fetchByDateRange(from startDate: Date, to endDate: Date) async throws -> [Transaction]
}

class TransactionRepository: TransactionRepositoryProtocol {
    private let dataController: DataController
    private let context: NSManagedObjectContext
    
    init(dataController: DataController = .shared) {
        self.dataController = dataController
        self.context = dataController.container.viewContext
    }
    
    func fetchAll() async throws -> [Transaction] {
        try await fetch(predicate: nil, sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)])
    }
    
    func fetch(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]) async throws -> [Transaction] {
        let request = Transaction.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        return try await context.perform {
            try self.context.fetch(request)
        }
    }
    
    func create(amount: Double, type: String, date: Date, note: String?, category: Category?) async throws -> Transaction {
        return try await context.perform {
            let transaction = Transaction(context: self.context)
            transaction.id = UUID()
            transaction.amount = amount
            transaction.type = type
            transaction.date = date
            transaction.note = note
            transaction.category = category
            
            try self.context.save()
            return transaction
        }
    }
    
    func update(_ transaction: Transaction) async throws {
        try await context.perform {
            guard self.context.hasChanges else { return }
            try self.context.save()
        }
    }
    
    func delete(_ transaction: Transaction) async throws {
        try await context.perform {
            self.context.delete(transaction)
            try self.context.save()
        }
    }
    
    func fetchByDateRange(from startDate: Date, to endDate: Date) async throws -> [Transaction] {
        let predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        return try await fetch(
            predicate: predicate,
            sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        )
    }
}