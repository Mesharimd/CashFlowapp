# CashFlow - Personal Finance Tracker for iOS

A beautifully designed iOS app for tracking personal finances, built with SwiftUI and Core Data.

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green.svg)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)

## 📱 Features

- **📊 Dashboard Overview** - View your current balance, monthly income/expenses at a glance
- **💰 Transaction Management** - Add, edit, and delete transactions with custom categories
- **🏷️ Category Organization** - Create custom categories with colors and icons
- **🔍 Search & Filter** - Quickly find transactions with powerful search and filtering
- **🌓 Dark Mode Support** - Automatic adaptation to system theme
- **💾 Offline First** - All data stored locally using Core Data

## 🛠️ Tech Stack

- **UI Framework**: SwiftUI
- **Data Persistence**: Core Data
- **Architecture**: MVVM (Model-View-ViewModel)
- **Minimum iOS**: 17.0
- **Language**: Swift 5.9

## 📋 Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## 🚀 Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/Mesharimd/CashFlowapp.git
   cd CashFlowapp
   ```

2. **Open in Xcode**
   ```bash
   open CashFlowapp.xcodeproj
   ```

3. **Build and Run**
   - Select a simulator or connected device
   - Press `Cmd + R` to build and run

## 📁 Project Structure

```
CashFlowapp/
├── Models/
│   └── DataController.swift      # Core Data stack management
├── Views/
│   ├── DashboardView.swift       # Main dashboard screen
│   ├── TransactionListView.swift # Transaction list screen
│   ├── TransactionFormView.swift # Add/Edit transaction form
│   └── CategoryManagerView.swift # Category management screen
├── ViewModels/
│   ├── DashboardViewModel.swift
│   ├── TransactionListViewModel.swift
│   ├── TransactionFormViewModel.swift
│   └── CategoryViewModel.swift
├── Repositories/
│   ├── TransactionRepository.swift
│   └── CategoryRepository.swift
└── Design/
    └── Theme.swift               # App-wide design system
```

## 🎨 Architecture

The app follows the **MVVM (Model-View-ViewModel)** pattern:

- **Models**: Core Data entities (Transaction, Category)
- **Views**: SwiftUI views for the user interface
- **ViewModels**: Business logic and data management
- **Repositories**: Data access layer for Core Data operations

## 🔑 Key Features Implementation

### Dashboard
- Real-time balance calculation
- Monthly income/expense summary
- Top spending categories
- Recent transactions preview

### Transaction Management
- Add income/expense transactions
- Categorize with custom categories
- Add notes and timestamps
- Swipe to delete functionality

### Category System
- Create custom categories
- Choose from preset icons
- Select category colors
- Track spending per category

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Meshari**
- GitHub: [@Mesharimd](https://github.com/Mesharimd)
- LinkedIn: [Meshari AlDoweesh](https://linkedin.com/in/mesharidoweesh)

## 🙏 Acknowledgments

- Built with SwiftUI and Core Data
- Icons from SF Symbols
- Inspired by modern finance apps

---

Made with ❤️ using Swift and SwiftUI
