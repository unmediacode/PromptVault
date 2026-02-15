import CoreData
import Foundation

@objc(CategoryEntity)
public class CategoryEntity: NSManagedObject {
    @NSManaged public var id_: UUID?
    @NSManaged public var name_: String?
    @NSManaged public var icon_: String?
    @NSManaged public var order_: Int16
    @NSManaged public var prompts_: NSSet?

    nonisolated public var id: UUID {
        get { id_ ?? UUID() }
        set { id_ = newValue }
    }

    nonisolated public var name: String {
        get { name_ ?? "" }
        set { name_ = newValue }
    }

    nonisolated public var icon: String {
        get { icon_ ?? "folder" }
        set { icon_ = newValue }
    }

    nonisolated public var order: Int16 {
        get { order_ }
        set { order_ = newValue }
    }

    nonisolated public var prompts: [PromptEntity] {
        let set = prompts_ as? Set<PromptEntity> ?? []
        return set.sorted { ($0.updatedAt) > ($1.updatedAt) }
    }

    nonisolated public var promptCount: Int {
        (prompts_ as? Set<PromptEntity>)?.count ?? 0
    }
}

extension CategoryEntity {
    static func create(
        in context: NSManagedObjectContext,
        name: String,
        icon: String = "folder",
        order: Int16 = 0
    ) -> CategoryEntity {
        let category = CategoryEntity(context: context)
        category.id_ = UUID()
        category.name_ = name
        category.icon_ = icon
        category.order_ = order
        return category
    }
}
