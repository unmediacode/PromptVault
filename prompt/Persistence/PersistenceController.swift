import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let coding = CategoryEntity.create(in: context, name: "Coding", icon: "chevron.left.forwardslash.chevron.right", order: 0)
        let writing = CategoryEntity.create(in: context, name: "Writing", icon: "pencil", order: 1)
        let analysis = CategoryEntity.create(in: context, name: "Analysis", icon: "chart.bar", order: 2)

        let p1 = PromptEntity.create(in: context, title: "Swift Code Review", content: "Review the following Swift code for best practices, potential bugs, and performance improvements. Provide specific suggestions with code examples.", category: coding)
        p1.isFavorite_ = true

        _ = PromptEntity.create(in: context, title: "Blog Post Draft", content: "Write a blog post about the following topic. Use a conversational tone, include practical examples, and structure it with clear headings.", category: writing)

        _ = PromptEntity.create(in: context, title: "Data Analysis", content: "Analyze the following dataset and provide insights on trends, outliers, and actionable recommendations.", category: analysis)

        _ = PromptEntity.create(in: context, title: "API Documentation", content: "Generate comprehensive API documentation for the following endpoints, including request/response examples.", category: coding)

        do {
            try context.save()
        } catch {
            print("Preview save error: \(error)")
        }

        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.createManagedObjectModel()
        container = NSPersistentContainer(name: "PromptVault", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("CoreData load error: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Programmatic CoreData Model

    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // MARK: PromptEntity
        let promptEntity = NSEntityDescription()
        promptEntity.name = "PromptEntity"
        promptEntity.managedObjectClassName = "PromptEntity"

        let promptId = NSAttributeDescription()
        promptId.name = "id_"
        promptId.attributeType = .UUIDAttributeType
        promptId.isOptional = true

        let promptTitle = NSAttributeDescription()
        promptTitle.name = "title_"
        promptTitle.attributeType = .stringAttributeType
        promptTitle.isOptional = true

        let promptContent = NSAttributeDescription()
        promptContent.name = "content_"
        promptContent.attributeType = .stringAttributeType
        promptContent.isOptional = true

        let promptIsFavorite = NSAttributeDescription()
        promptIsFavorite.name = "isFavorite_"
        promptIsFavorite.attributeType = .booleanAttributeType
        promptIsFavorite.defaultValue = false

        let promptCreatedAt = NSAttributeDescription()
        promptCreatedAt.name = "createdAt_"
        promptCreatedAt.attributeType = .dateAttributeType
        promptCreatedAt.isOptional = true

        let promptUpdatedAt = NSAttributeDescription()
        promptUpdatedAt.name = "updatedAt_"
        promptUpdatedAt.attributeType = .dateAttributeType
        promptUpdatedAt.isOptional = true

        promptEntity.properties = [promptId, promptTitle, promptContent, promptIsFavorite, promptCreatedAt, promptUpdatedAt]

        // MARK: CategoryEntity
        let categoryEntity = NSEntityDescription()
        categoryEntity.name = "CategoryEntity"
        categoryEntity.managedObjectClassName = "CategoryEntity"

        let categoryId = NSAttributeDescription()
        categoryId.name = "id_"
        categoryId.attributeType = .UUIDAttributeType
        categoryId.isOptional = true

        let categoryName = NSAttributeDescription()
        categoryName.name = "name_"
        categoryName.attributeType = .stringAttributeType
        categoryName.isOptional = true

        let categoryIcon = NSAttributeDescription()
        categoryIcon.name = "icon_"
        categoryIcon.attributeType = .stringAttributeType
        categoryIcon.isOptional = true

        let categoryOrder = NSAttributeDescription()
        categoryOrder.name = "order_"
        categoryOrder.attributeType = .integer16AttributeType
        categoryOrder.defaultValue = 0

        categoryEntity.properties = [categoryId, categoryName, categoryIcon, categoryOrder]

        // MARK: Relationships
        let categoryRelation = NSRelationshipDescription()
        categoryRelation.name = "category"
        categoryRelation.destinationEntity = categoryEntity
        categoryRelation.minCount = 0
        categoryRelation.maxCount = 1
        categoryRelation.deleteRule = .nullifyDeleteRule
        categoryRelation.isOptional = true

        let promptsRelation = NSRelationshipDescription()
        promptsRelation.name = "prompts_"
        promptsRelation.destinationEntity = promptEntity
        promptsRelation.minCount = 0
        promptsRelation.maxCount = 0 // to-many
        promptsRelation.deleteRule = .cascadeDeleteRule
        promptsRelation.isOptional = true

        categoryRelation.inverseRelationship = promptsRelation
        promptsRelation.inverseRelationship = categoryRelation

        promptEntity.properties.append(categoryRelation)
        categoryEntity.properties.append(promptsRelation)

        model.entities = [promptEntity, categoryEntity]
        return model
    }

    // MARK: - Save

    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("CoreData save error: \(error)")
        }
    }
}
