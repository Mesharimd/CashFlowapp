import Foundation
import CoreData
import Combine

@MainActor
class CategoryViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingAddCategory = false
    @Published var editingCategory: Category?
    
    @Published var newCategoryName = ""
    @Published var newCategoryIcon = "tag.fill"
    @Published var newCategoryColor = "#4ECDC4"
    
    private let categoryRepository: CategoryRepositoryProtocol
    
    let availableIcons = [
        "fork.knife", "car.fill", "bag.fill", "tv.fill", "bolt.fill",
        "heart.fill", "house.fill", "airplane", "tram.fill", "gift.fill",
        "cart.fill", "creditcard.fill", "phone.fill", "book.fill", "gamecontroller.fill",
        "music.note", "film.fill", "camera.fill", "paintbrush.fill", "hammer.fill"
    ]
    
    let availableColors = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FECA57",
        "#FF6B9D", "#95E1D3", "#A8E6CF", "#C7CEEA", "#FFDAA5",
        "#FFB6C1", "#87CEEB", "#98D8C8", "#F7DC6F", "#BB8FCE"
    ]
    
    var isValidForm: Bool {
        !newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    init(categoryRepository: CategoryRepositoryProtocol = CategoryRepository()) {
        self.categoryRepository = categoryRepository
    }
    
    func loadCategories() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedCategories = try await categoryRepository.fetchAll()
            await MainActor.run {
                self.categories = fetchedCategories
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func createCategory() async {
        guard isValidForm else { return }
        
        do {
            _ = try await categoryRepository.create(
                name: newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines),
                icon: newCategoryIcon,
                color: newCategoryColor
            )
            
            await MainActor.run {
                self.newCategoryName = ""
                self.newCategoryIcon = "tag.fill"
                self.newCategoryColor = "#4ECDC4"
                self.showingAddCategory = false
            }
            
            await loadCategories()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func updateCategory(_ category: Category) async {
        do {
            try await categoryRepository.update(category)
            await loadCategories()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteCategory(_ category: Category) async {
        do {
            try await categoryRepository.delete(category)
            await loadCategories()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func prepareForEdit(_ category: Category) {
        editingCategory = category
        newCategoryName = category.name ?? ""
        newCategoryIcon = category.icon ?? "tag.fill"
        newCategoryColor = category.color ?? "#4ECDC4"
    }
    
    func saveEditedCategory() async {
        guard let category = editingCategory, isValidForm else { return }
        
        category.name = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        category.icon = newCategoryIcon
        category.color = newCategoryColor
        
        await updateCategory(category)
        
        await MainActor.run {
            self.editingCategory = nil
            self.newCategoryName = ""
            self.newCategoryIcon = "tag.fill"
            self.newCategoryColor = "#4ECDC4"
        }
    }
    
    func cancelEdit() {
        editingCategory = nil
        newCategoryName = ""
        newCategoryIcon = "tag.fill"
        newCategoryColor = "#4ECDC4"
    }
}