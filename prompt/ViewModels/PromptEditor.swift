import Combine
import CoreData
import Foundation

class PromptEditor: ObservableObject {
    @Published var title: String = ""
    @Published var content: String = ""
    @Published var isFavorite: Bool = false
    @Published var category: CategoryEntity?
    @Published var createdAt: Date = Date()
    @Published var updatedAt: Date = Date()

    private(set) var promptObjectID: NSManagedObjectID?
    private var context: NSManagedObjectContext?
    private var autosaveCancellable: AnyCancellable?
    private var isLoading: Bool = false

    init() {
        setupAutosave()
    }
    
    private func setupAutosave() {
        // Auto-save text changes after 0.5s of inactivity
        autosaveCancellable = Publishers.Merge(
            $title.dropFirst().map { _ in () },  // dropFirst to ignore initial value
            $content.dropFirst().map { _ in () }  // dropFirst to ignore initial value
        )
        .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
        .sink { [weak self] in
            guard let self = self, !self.isLoading else { return }
            self.saveCurrentPrompt()
        }
    }

    func load(_ prompt: PromptEntity, context: NSManagedObjectContext) {
        // Don't reload if it's the same prompt
        if promptObjectID == prompt.objectID {
            return
        }
        
        // Save current prompt before switching
        saveCurrentPrompt()
        
        // Cancel any pending autosave operations and mark as loading
        autosaveCancellable?.cancel()
        isLoading = true

        // CRITICAL: Update the promptObjectID FIRST before changing any published properties
        // This ensures any autosave triggered will save to the correct prompt
        self.context = context
        self.promptObjectID = prompt.objectID

        // Now update the published properties (which trigger @Published notifications)
        self.title = prompt.title_ ?? ""
        self.content = prompt.content_ ?? ""
        self.isFavorite = prompt.isFavorite_
        self.category = prompt.category
        self.createdAt = prompt.createdAt_ ?? Date()
        self.updatedAt = prompt.updatedAt_ ?? Date()
        
        // Restart autosave subscription
        setupAutosave()
        
        // Mark loading as complete
        isLoading = false
    }

    func saveCurrentPrompt() {
        guard let oid = promptObjectID,
              let ctx = context else { return }
        
        // Try to get the object, but if it's deleted or doesn't exist, just return
        guard let prompt = try? ctx.existingObject(with: oid) as? PromptEntity,
              !prompt.isDeleted,
              !prompt.isFault else { 
            return 
        }

        prompt.title_ = title
        prompt.content_ = content
        prompt.isFavorite_ = isFavorite
        prompt.category = category
        prompt.updatedAt_ = Date()

        do {
            try ctx.save()
        } catch {
            print("Save error: \(error)")
        }
    }

    func clear(saveFirst: Bool = true) {
        // Cancel any pending autosave operations first
        autosaveCancellable?.cancel()
        
        if saveFirst {
            isLoading = true
            saveCurrentPrompt()
        }
        
        promptObjectID = nil
        context = nil
        title = ""
        content = ""
        isFavorite = false
        category = nil
        
        // Always restart autosave subscription
        setupAutosave()
        
        if saveFirst {
            isLoading = false
        }
    }
}
