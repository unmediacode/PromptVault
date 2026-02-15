import SwiftUI
import CoreData

struct PromptListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var viewModel: PromptListViewModel
    @ObservedObject var categoryVM: CategoryViewModel
    @Binding var selectedPrompt: PromptEntity?
    var filter: SidebarFilter

    @State private var prompts: [PromptEntity] = []
    @State private var promptToDelete: PromptEntity?

    private var filteredPrompts: [PromptEntity] {
        var result = prompts

        switch viewModel.sortOption {
        case .dateUpdated:
            result.sort { $0.updatedAt > $1.updatedAt }
        case .dateCreated:
            result.sort { $0.createdAt > $1.createdAt }
        case .titleAZ:
            result.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .titleZA:
            result.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        }

        guard !viewModel.searchText.isEmpty else { return result }
        let query = viewModel.searchText.lowercased()
        return result.filter {
            $0.title.lowercased().contains(query) ||
            $0.content.lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if filteredPrompts.isEmpty {
                emptyState
            } else {
                List(selection: $selectedPrompt) {
                    ForEach(filteredPrompts, id: \.objectID) { prompt in
                        PromptRowView(prompt: prompt)
                            .tag(prompt)
                            .contextMenu {
                                contextMenuItems(for: prompt)
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search prompts...")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    ForEach(SortOption.allCases) { option in
                        Button {
                            viewModel.sortOption = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if viewModel.sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .accessibilityLabel("Sort prompts")
                }
            }
        }
        .alert("Delete Prompt?", isPresented: Binding(
            get: { promptToDelete != nil },
            set: { if !$0 { promptToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { promptToDelete = nil }
            Button("Delete", role: .destructive) {
                if let prompt = promptToDelete {
                    if selectedPrompt == prompt { selectedPrompt = nil }
                    viewModel.deletePrompt(prompt)
                }
                promptToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .navigationTitle(filter.label)
        .onAppear { fetchPrompts() }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: viewContext)) { _ in
            fetchPrompts()
        }
    }

    private func fetchPrompts() {
        let request = NSFetchRequest<PromptEntity>(entityName: "PromptEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt_", ascending: false)]

        switch filter {
        case .all:
            request.predicate = nil
        case .favorites:
            request.predicate = NSPredicate(format: "isFavorite_ == YES")
        case .recent:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            request.predicate = NSPredicate(format: "updatedAt_ >= %@", weekAgo as NSDate)
        case .category(let category):
            request.predicate = NSPredicate(format: "category == %@", category)
        }

        do {
            prompts = try viewContext.fetch(request)
        } catch {
            print("Fetch prompts error: \(error)")
        }
    }

    @ViewBuilder
    private func contextMenuItems(for prompt: PromptEntity) -> some View {
        Button {
            ClipboardManager.copyToClipboard(prompt.content)
        } label: {
            Label("Copy Content", systemImage: "doc.on.doc")
        }

        Button {
            let copy = viewModel.duplicatePrompt(prompt)
            selectedPrompt = copy
        } label: {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }

        Button {
            viewModel.toggleFavorite(prompt)
        } label: {
            Label(
                prompt.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                systemImage: prompt.isFavorite ? "star.slash" : "star"
            )
        }

        if !categoryVM.categories.isEmpty {
            Menu("Move to Category") {
                Button("Uncategorized") {
                    viewModel.movePrompt(prompt, to: nil)
                }
                Divider()
                ForEach(categoryVM.categories, id: \.objectID) { category in
                    Button {
                        viewModel.movePrompt(prompt, to: category)
                    } label: {
                        Label(category.name, systemImage: category.icon)
                    }
                }
            }
        }

        Divider()

        Button(role: .destructive) {
            promptToDelete = prompt
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            if !viewModel.searchText.isEmpty {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundStyle(.tertiary)
                Text("No results for \"\(viewModel.searchText)\"")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("Try a different search term.")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                Image(systemName: "doc.text")
                    .font(.system(size: 40))
                    .foregroundStyle(.tertiary)
                Text("No Prompts")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("Press ⌘N to create a new prompt.")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    let controller = PersistenceController.preview
    let context = controller.container.viewContext
    PromptListView(
        viewModel: PromptListViewModel(context: context),
        categoryVM: CategoryViewModel(context: context),
        selectedPrompt: .constant(nil),
        filter: .all
    )
    .environment(\.managedObjectContext, context)
    .frame(width: 300, height: 500)
}
