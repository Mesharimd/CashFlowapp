import SwiftUI

struct TransactionFormView: View {
    @StateObject private var viewModel: TransactionFormViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var amountFieldFocused: Bool
    
    init(transaction: Transaction? = nil) {
        _viewModel = StateObject(wrappedValue: TransactionFormViewModel(transaction: transaction))
    }
    
    var body: some View {
        NavigationView {
            Form {
                transactionTypeSection
                amountSection
                detailsSection
                categorySection
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(Theme.dangerColor)
                            .font(Theme.caption)
                    }
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(viewModel.saveButtonTitle) {
                        Task {
                            if await viewModel.saveTransaction() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValidForm || viewModel.isLoading)
                }
            }
            .task {
                await viewModel.loadCategories()
                amountFieldFocused = true
            }
        }
    }
    
    private var transactionTypeSection: some View {
        Section {
            Picker("Type", selection: $viewModel.transactionType) {
                ForEach(TransactionFormViewModel.TransactionType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private var amountSection: some View {
        Section(header: Text("Amount")) {
            HStack {
                Text("$")
                    .font(Theme.title2)
                    .foregroundColor(Theme.secondaryTextColor)
                
                TextField("0.00", text: $viewModel.amount)
                    .keyboardType(.decimalPad)
                    .font(Theme.title)
                    .focused($amountFieldFocused)
                    .onChange(of: viewModel.amount) { newValue in
                        let filtered = newValue.filter { "0123456789.".contains($0) }
                        if filtered != newValue {
                            viewModel.amount = filtered
                        }
                    }
            }
        }
    }
    
    private var detailsSection: some View {
        Section(header: Text("Details")) {
            TextField("Description", text: $viewModel.note)
                .textFieldStyle(PlainTextFieldStyle())
            
            DatePicker("Date", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
        }
    }
    
    private var categorySection: some View {
        Section(header: Text("Category")) {
            if viewModel.categories.isEmpty {
                HStack {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("Loading categories...")
                        .font(Theme.caption)
                        .foregroundColor(Theme.secondaryTextColor)
                }
            } else {
                ForEach(viewModel.categories) { category in
                    CategoryRow(
                        category: category,
                        isSelected: viewModel.selectedCategory?.id == category.id,
                        action: {
                            viewModel.selectedCategory = category
                        }
                    )
                }
            }
        }
    }
}

struct CategoryRow: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(Color(hex: category.color ?? "#808080"))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: category.icon ?? "tag.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                    )
                
                Text(category.name ?? "Unknown")
                    .font(Theme.body)
                    .foregroundColor(Theme.textColor)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.primaryColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TransactionFormView()
        .environment(\.managedObjectContext, DataController.preview.container.viewContext)
}