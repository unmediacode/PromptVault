import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var promptVM: PromptListViewModel
    @StateObject private var categoryVM: CategoryViewModel
    @StateObject private var editor = PromptEditor()
    @State private var selectedFilter: SidebarFilter? = .all
    @State private var selectedPrompts: Set<PromptEntity> = []
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    private var selectedPrompt: PromptEntity? {
        selectedPrompts.first
    }

    init(context: NSManagedObjectContext) {
        _promptVM = StateObject(wrappedValue: PromptListViewModel(context: context))
        _categoryVM = StateObject(wrappedValue: CategoryViewModel(context: context))
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                selectedFilter: $selectedFilter,
                categoryVM: categoryVM
            )
            .frame(minWidth: 180)
        } content: {
            if let filter = selectedFilter {
                PromptListView(
                    viewModel: promptVM,
                    categoryVM: categoryVM,
                    selectedPrompts: $selectedPrompts,
                    filter: filter
                )
                .frame(minWidth: 250)
                .id(filter)
            } else {
                Text("Select a filter")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } detail: {
            if selectedPrompt != nil {
                PromptDetailView(
                    editor: editor,
                    viewModel: promptVM,
                    categoryVM: categoryVM
                )
                .frame(minWidth: 350)
            } else {
                PromptDetailEmptyView()
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .onDeleteCommand {
            deleteSelectedPrompts()
        }
        .onChange(of: selectedPrompt?.objectID) { _, newValue in
            if let newValue,
               let prompt = try? viewContext.existingObject(with: newValue) as? PromptEntity {
                editor.load(prompt, context: viewContext)
            } else {
                editor.clear()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewPrompt)) { _ in
            createNewPrompt()
        }
        .onReceive(NotificationCenter.default.publisher(for: .copySelectedPrompt)) { _ in
            if let prompt = selectedPrompt {
                ClipboardManager.copyToClipboard(prompt.content)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .deleteSelectedPrompt)) { _ in
            deleteSelectedPrompts()
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in
            // .searchable handles ⌘F natively
        }
    }
    
    private func deleteSelectedPrompts() {
        guard !selectedPrompts.isEmpty else { return }
        
        // If we're deleting the currently edited prompt, clear the editor
        if let currentPrompt = selectedPrompt, selectedPrompts.contains(currentPrompt) {
            editor.clear(saveFirst: false)
        }
        
        // Delete all selected prompts
        for prompt in selectedPrompts {
            promptVM.deletePrompt(prompt)
        }
        
        // Clear selection
        selectedPrompts.removeAll()
    }

    private func createNewPrompt() {
        // The editor will save the current prompt automatically when loading the new one
        var category: CategoryEntity?
        if case .category(let categoryID) = selectedFilter {
            category = try? viewContext.existingObject(with: categoryID) as? CategoryEntity
        }
        let newPrompt = promptVM.addPrompt(category: category)
        selectedPrompts = [newPrompt]
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let createNewPrompt = Notification.Name("createNewPrompt")
    static let copySelectedPrompt = Notification.Name("copySelectedPrompt")
    static let deleteSelectedPrompt = Notification.Name("deleteSelectedPrompt")
    static let focusSearch = Notification.Name("focusSearch")
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    ContentView(context: context)
        .environment(\.managedObjectContext, context)
}
