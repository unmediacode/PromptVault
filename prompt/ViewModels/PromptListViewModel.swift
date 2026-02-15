import Combine
import CoreData
import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case dateCreated = "Date Created"
    case titleAZ = "Title A-Z"
    case titleZA = "Title Z-A"

    var id: String { rawValue }

    var sortDescriptor: NSSortDescriptor {
        switch self {
        case .dateCreated: NSSortDescriptor(key: "createdAt_", ascending: false)
        case .titleAZ: NSSortDescriptor(key: "title_", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        case .titleZA: NSSortDescriptor(key: "title_", ascending: false, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        }
    }
}

class PromptListViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var sortOption: SortOption = .dateCreated

    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }

    func addPrompt(category: CategoryEntity? = nil) -> PromptEntity {
        let prompt = PromptEntity.create(in: viewContext, category: category)
        save()
        return prompt
    }

    func deletePrompt(_ prompt: PromptEntity) {
        viewContext.delete(prompt)
        save()
    }

    func toggleFavorite(_ prompt: PromptEntity) {
        prompt.isFavorite = !prompt.isFavorite
        save()
    }

    func duplicatePrompt(_ prompt: PromptEntity) -> PromptEntity {
        let copy = prompt.duplicate(in: viewContext)
        save()
        return copy
    }

    func movePrompt(_ prompt: PromptEntity, to category: CategoryEntity?) {
        prompt.category = category
        prompt.updatedAt_ = Date()
        save()
    }

    func save() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            print("Save prompt error: \(error)")
        }
    }
}
