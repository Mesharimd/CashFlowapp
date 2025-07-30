import SwiftUI

struct CategoryManagerView: View {
    @StateObject private var viewModel = CategoryViewModel()
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: Category?
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.categories.isEmpty {
                    emptyStateView
                } else {
                    categoriesList
                }
            }
            .background(Theme.backgroundColor)
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showingAddCategory = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Theme.primaryColor)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddCategory) {
                CategoryFormSheet(viewModel: viewModel, mode: .add)
            }
            .sheet(item: $viewModel.editingCategory) { _ in
                CategoryFormSheet(viewModel: viewModel, mode: .edit)
            }
            .alert("Delete Category", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let category = categoryToDelete {
                        Task {
                            await viewModel.deleteCategory(category)
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this category? This action cannot be undone.")
            }
            .task {
                await viewModel.loadCategories()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tag.slash")
                .font(.system(size: 60))
                .foregroundColor(Theme.secondaryTextColor)
            
            Text("No categories yet")
                .font(Theme.headline)
                .foregroundColor(Theme.textColor)
            
            Text("Create categories to organize your transactions")
                .font(Theme.subheadline)
                .foregroundColor(Theme.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            Button(action: { viewModel.showingAddCategory = true }) {
                Label("Add Category", systemImage: "plus.circle")
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
    
    private var categoriesList: some View {
        List {
            ForEach(viewModel.categories) { category in
                CategoryListRow(category: category)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.prepareForEdit(category)
                    }
            }
            .onDelete { offsets in
                for index in offsets {
                    categoryToDelete = viewModel.categories[index]
                    showingDeleteAlert = true
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            await viewModel.loadCategories()
        }
    }
}

struct CategoryListRow: View {
    let category: Category
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: category.color ?? "#808080"))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: category.icon ?? "tag.fill")
                        .foregroundColor(.white)
                )
            
            Text(category.name ?? "Unknown")
                .font(Theme.body)
            
            Spacer()
            
            // Transaction count temporarily disabled until Core Data relationships are configured
            /*if let transactionCount = category.transactions?.count, transactionCount > 0 {
                Text("\(transactionCount)")
                    .font(Theme.caption)
                    .foregroundColor(Theme.secondaryTextColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.secondaryBackgroundColor)
                    .cornerRadius(8)
            }*/
        }
        .padding(.vertical, 4)
    }
}

struct CategoryFormSheet: View {
    @ObservedObject var viewModel: CategoryViewModel
    @Environment(\.dismiss) private var dismiss
    let mode: Mode
    
    enum Mode {
        case add, edit
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category Name")) {
                    TextField("Enter category name", text: $viewModel.newCategoryName)
                }
                
                Section(header: Text("Icon")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 20) {
                        ForEach(viewModel.availableIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundColor(viewModel.newCategoryIcon == icon ? .white : Theme.textColor)
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(viewModel.newCategoryIcon == icon ? Theme.primaryColor : Theme.secondaryBackgroundColor)
                                )
                                .onTapGesture {
                                    viewModel.newCategoryIcon = icon
                                }
                        }
                    }
                    .padding(.vertical)
                }
                
                Section(header: Text("Color")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 20) {
                        ForEach(viewModel.availableColors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(viewModel.newCategoryColor == color ? Color.black : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    viewModel.newCategoryColor = color
                                }
                        }
                    }
                    .padding(.vertical)
                }
                
                Section(header: Text("Preview")) {
                    HStack {
                        Circle()
                            .fill(Color(hex: viewModel.newCategoryColor))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: viewModel.newCategoryIcon)
                                    .foregroundColor(.white)
                                    .font(.title2)
                            )
                        
                        Text(viewModel.newCategoryName.isEmpty ? "Category Name" : viewModel.newCategoryName)
                            .font(Theme.headline)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(mode == .add ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.cancelEdit()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(mode == .add ? "Add" : "Save") {
                        Task {
                            if mode == .add {
                                await viewModel.createCategory()
                            } else {
                                await viewModel.saveEditedCategory()
                            }
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.isValidForm)
                }
            }
        }
    }
}

#Preview {
    CategoryManagerView()
        .environment(\.managedObjectContext, DataController.preview.container.viewContext)
}