import CoreData
import Foundation

@objc(PromptEntity)
public class PromptEntity: NSManagedObject {
    @NSManaged public var id_: UUID?
    @NSManaged public var title_: String?
    @NSManaged public var content_: String?
    @NSManaged public var isFavorite_: Bool
    @NSManaged public var createdAt_: Date?
    @NSManaged public var updatedAt_: Date?
    @NSManaged public var category: CategoryEntity?

    nonisolated public var id: UUID {
        get { id_ ?? UUID() }
        set { id_ = newValue }
    }

    nonisolated public var title: String {
        get { title_ ?? "" }
        set { title_ = newValue; updatedAt_ = Date() }
    }

    nonisolated public var content: String {
        get { content_ ?? "" }
        set { content_ = newValue; updatedAt_ = Date() }
    }

    nonisolated public var isFavorite: Bool {
        get { isFavorite_ }
        set { isFavorite_ = newValue; updatedAt_ = Date() }
    }

    nonisolated public var createdAt: Date {
        get { createdAt_ ?? Date() }
        set { createdAt_ = newValue }
    }

    nonisolated public var updatedAt: Date {
        get { updatedAt_ ?? Date() }
        set { updatedAt_ = newValue }
    }

    nonisolated public var categoryName: String {
        category?.name ?? "Uncategorized"
    }

    nonisolated public var contentPreview: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 100 { return trimmed }
        return String(trimmed.prefix(100)) + "..."
    }
}

extension PromptEntity {
    static func create(
        in context: NSManagedObjectContext,
        title: String = "New Prompt",
        content: String = "",
        category: CategoryEntity? = nil
    ) -> PromptEntity {
        let prompt = PromptEntity(context: context)
        prompt.id_ = UUID()
        prompt.title_ = title
        prompt.content_ = content
        prompt.isFavorite_ = false
        prompt.createdAt_ = Date()
        prompt.updatedAt_ = Date()
        prompt.category = category
        return prompt
    }

    nonisolated func duplicate(in context: NSManagedObjectContext) -> PromptEntity {
        let copy = PromptEntity(context: context)
        copy.id_ = UUID()
        copy.title_ = (title_ ?? "") + " (Copy)"
        copy.content_ = content_
        copy.isFavorite_ = false
        copy.createdAt_ = Date()
        copy.updatedAt_ = Date()
        copy.category = category
        return copy
    }
}
