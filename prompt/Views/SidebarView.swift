import SwiftUI

enum SidebarFilter: Hashable {
    case all
    case favorites
    case recent
    case category(CategoryEntity)

    var label: String {
        switch self {
        case .all: "All Prompts"
        case .favorites: "Favorites"
        case .recent: "Recent"
        case .category(let cat): cat.name
        }
    }

    var icon: String {
        switch self {
        case .all: "tray.2"
        case .favorites: "star"
        case .recent: "clock"
        case .category(let cat): cat.icon
        }
    }
}

struct SidebarView: View {
    @Binding var selectedFilter: SidebarFilter?
    @ObservedObject var categoryVM: CategoryViewModel
    @State private var showAddCategory = false
    @State private var renamingCategory: CategoryEntity?
    @State private var renameText: String = ""

    var body: some View {
        List(selection: $selectedFilter) {
            Section("Smart Filters") {
                Label("All Prompts", systemImage: "tray.2")
                    .tag(SidebarFilter.all)
                    .accessibilityLabel("All Prompts")

                Label("Favorites", systemImage: "star")
                    .tag(SidebarFilter.favorites)
                    .accessibilityLabel("Favorites")

                Label("Recent", systemImage: "clock")
                    .tag(SidebarFilter.recent)
                    .accessibilityLabel("Recent prompts")
            }

            Section {
                ForEach(categoryVM.categories, id: \.objectID) { category in
                    Label(category.name, systemImage: category.icon)
                        .tag(SidebarFilter.category(category))
                        .badge(category.promptCount)
                        .contextMenu {
                            Button("Rename") {
                                renameText = category.name
                                renamingCategory = category
                            }
                            Button("Delete", role: .destructive) {
                                categoryVM.deleteCategory(category)
                                if case .category(let selected) = selectedFilter, selected == category {
                                    selectedFilter = .all
                                }
                            }
                        }
                }
            } header: {
                HStack {
                    Text("Categories")
                    Spacer()
                    Button {
                        showAddCategory = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add category")
                }
            }
        }
        .listStyle(.sidebar)
        .sheet(isPresented: $showAddCategory) {
            AddCategorySheet { name, icon in
                categoryVM.addCategory(name: name, icon: icon)
            }
        }
        .alert("Rename Category", isPresented: Binding(
            get: { renamingCategory != nil },
            set: { if !$0 { renamingCategory = nil } }
        )) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) { renamingCategory = nil }
            Button("Save") {
                if let cat = renamingCategory {
                    categoryVM.renameCategory(cat, to: renameText)
                }
                renamingCategory = nil
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    SidebarView(
        selectedFilter: .constant(.all),
        categoryVM: CategoryViewModel(context: context)
    )
    .frame(width: 220, height: 400)
}
