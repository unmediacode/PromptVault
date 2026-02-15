import Combine
import CoreData
import Foundation

class CategoryViewModel: ObservableObject {
    @Published var categories: [CategoryEntity] = []

    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchCategories()
    }

    func fetchCategories() {
        let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "order_", ascending: true)]

        do {
            categories = try viewContext.fetch(request)
        } catch {
            print("Fetch categories error: \(error)")
        }
    }

    func addCategory(name: String, icon: String = "folder") {
        let maxOrder = categories.map(\.order).max() ?? -1
        _ = CategoryEntity.create(in: viewContext, name: name, icon: icon, order: maxOrder + 1)
        save()
        fetchCategories()
    }

    func renameCategory(_ category: CategoryEntity, to name: String) {
        category.name = name
        save()
        fetchCategories()
    }

    func updateIcon(_ category: CategoryEntity, icon: String) {
        category.icon = icon
        save()
        fetchCategories()
    }

    func deleteCategory(_ category: CategoryEntity) {
        viewContext.delete(category)
        save()
        fetchCategories()
    }

    private func save() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            print("Save category error: \(error)")
        }
    }
}
