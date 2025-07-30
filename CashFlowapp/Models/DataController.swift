import CoreData
import Foundation

class DataController: ObservableObject {
    static let shared = DataController()
    static var preview: DataController = {
        let controller = DataController(inMemory: true)
        controller.createSampleData()
        return controller
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Model")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load data: \(error.localizedDescription)")
            }
        }
    }
    
    func save() {
        guard container.viewContext.hasChanges else { return }
        
        do {
            try container.viewContext.save()
        } catch {
            print("Failed to save changes: \(error.localizedDescription)")
        }
    }
    
    func createSampleData() {
        let viewContext = container.viewContext
        
        let categories = [
            ("Food & Dining", "fork.knife", "#FF6B6B"),
            ("Transportation", "car.fill", "#4ECDC4"),
            ("Shopping", "bag.fill", "#45B7D1"),
            ("Entertainment", "tv.fill", "#96CEB4"),
            ("Bills & Utilities", "bolt.fill", "#FECA57"),
            ("Healthcare", "heart.fill", "#FF6B9D"),
            ("Income", "dollarsign.circle.fill", "#95E1D3")
        ]
        
        var createdCategories: [Category] = []
        
        for (name, icon, color) in categories {
            let category = Category(context: viewContext)
            category.id = UUID()
            category.name = name
            category.icon = icon
            category.color = color
            createdCategories.append(category)
        }
        
        let transactions = [
            ("Grocery Store", -85.50, createdCategories[0], -2),
            ("Gas Station", -45.00, createdCategories[1], -3),
            ("Amazon Purchase", -125.99, createdCategories[2], -4),
            ("Netflix Subscription", -15.99, createdCategories[3], -5),
            ("Electric Bill", -120.00, createdCategories[4], -6),
            ("Doctor Visit", -150.00, createdCategories[5], -7),
            ("Salary", 3500.00, createdCategories[6], -8),
            ("Restaurant", -65.00, createdCategories[0], -9),
            ("Uber Ride", -25.00, createdCategories[1], -10),
            ("Clothing Store", -200.00, createdCategories[2], -11)
        ]
        
        for (note, amount, category, daysAgo) in transactions {
            let transaction = Transaction(context: viewContext)
            transaction.id = UUID()
            transaction.note = note
            transaction.amount = amount
            transaction.type = amount > 0 ? "income" : "expense"
            transaction.date = Calendar.current.date(byAdding: .day, value: daysAgo, to: Date())!
            transaction.category = category
        }
        
        save()
    }
}
