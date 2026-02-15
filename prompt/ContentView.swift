import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var promptVM: PromptListViewModel
    @StateObject private var categoryVM: CategoryViewModel
    @State private var selectedFilter: SidebarFilter? = .all
    @State private var selectedPrompt: PromptEntity?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

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
                    selectedPrompt: $selectedPrompt,
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
            if let prompt = selectedPrompt {
                PromptDetailView(
                    prompt: prompt,
                    viewModel: promptVM,
                    categoryVM: categoryVM
                )
                .id(prompt.objectID)
                .frame(minWidth: 350)
            } else {
                PromptDetailEmptyView()
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .onReceive(NotificationCenter.default.publisher(for: .createNewPrompt)) { _ in
            createNewPrompt()
        }
        .onReceive(NotificationCenter.default.publisher(for: .copySelectedPrompt)) { _ in
            if let prompt = selectedPrompt {
                ClipboardManager.copyToClipboard(prompt.content)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .deleteSelectedPrompt)) { _ in
            if let prompt = selectedPrompt {
                selectedPrompt = nil
                promptVM.deletePrompt(prompt)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in
            // .searchable handles ⌘F natively
        }
    }

    private func createNewPrompt() {
        // Save pending in-memory changes before creating new prompt
        promptVM.save()

        var category: CategoryEntity?
        if case .category(let cat) = selectedFilter {
            category = cat
        }
        let newPrompt = promptVM.addPrompt(category: category)
        selectedPrompt = newPrompt
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
