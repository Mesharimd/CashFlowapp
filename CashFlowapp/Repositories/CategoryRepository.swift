import CoreData
import Foundation

protocol CategoryRepositoryProtocol {
    func fetchAll() async throws -> [Category]
    func fetch(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]) async throws -> [Category]
    func create(name: String, icon: String?, color: String?) async throws -> Category
    func update(_ category: Category) async throws
    func delete(_ category: Category) async throws
    func fetchByName(_ name: String) async throws -> Category?
}

class CategoryRepository: CategoryRepositoryProtocol {
    private let dataController: DataController
    private let context: NSManagedObjectContext
    
    init(dataController: DataController = .shared) {
        self.dataController = dataController
        self.context = dataController.container.viewContext
    }
    
    func fetchAll() async throws -> [Category] {
        try await fetch(predicate: nil, sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)])
    }
    
    func fetch(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]) async throws -> [Category] {
        let request = Category.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        return try await context.perform {
            try self.context.fetch(request)
        }
    }
    
    func create(name: String, icon: String?, color: String?) async throws -> Category {
        return try await context.perform {
            let category = Category(context: self.context)
            category.id = UUID()
            category.name = name
            category.icon = icon
            category.color = color
            
            try self.context.save()
            return category
        }
    }
    
    func update(_ category: Category) async throws {
        try await context.perform {
            guard self.context.hasChanges else { return }
            try self.context.save()
        }
    }
    
    func delete(_ category: Category) async throws {
        try await context.perform {
            self.context.delete(category)
            try self.context.save()
        }
    }
    
    func fetchByName(_ name: String) async throws -> Category? {
        let predicate = NSPredicate(format: "name == %@", name)
        let categories = try await fetch(predicate: predicate, sortDescriptors: [])
        return categories.first
    }
}