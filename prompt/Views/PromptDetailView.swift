import SwiftUI

struct PromptDetailView: View {
    @ObservedObject var prompt: PromptEntity
    @ObservedObject var viewModel: PromptListViewModel
    @ObservedObject var categoryVM: CategoryViewModel
    @Environment(\.managedObjectContext) private var viewContext

    @State private var titleText: String = ""
    @State private var contentText: String = ""
    @State private var showCopied: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                TextField("Prompt Title", text: $titleText)
                    .textFieldStyle(.plain)
                    .font(.title2.bold())
                    .accessibilityLabel("Prompt title")

                Spacer()

                Button {
                    viewModel.toggleFavorite(prompt)
                } label: {
                    Image(systemName: prompt.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(prompt.isFavorite ? .yellow : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(prompt.isFavorite ? "Remove from favorites" : "Add to favorites")
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // Metadata row
            HStack(spacing: 12) {
                Picker("Category", selection: Binding(
                    get: { prompt.category },
                    set: { newCat in
                        viewModel.movePrompt(prompt, to: newCat)
                        categoryVM.fetchCategories()
                    }
                )) {
                    Text("Uncategorized").tag(nil as CategoryEntity?)
                    ForEach(categoryVM.categories, id: \.objectID) { cat in
                        Label(cat.name, systemImage: cat.icon).tag(cat as CategoryEntity?)
                    }
                }
                .frame(maxWidth: 200)
                .accessibilityLabel("Category picker")

                Spacer()

                Text("Created \(prompt.createdAt.shortFormatted)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Text("Updated \(prompt.updatedAt.relativeFormatted)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Divider()
                .padding(.top, 8)

            // Content editor
            TextEditor(text: $contentText)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .accessibilityLabel("Prompt content")

            Divider()

            // Bottom toolbar
            HStack {
                Text("\(contentText.count) characters")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                Button {
                    ClipboardManager.copyToClipboard(contentText)
                    withAnimation {
                        showCopied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showCopied = false
                        }
                    }
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Copy prompt to clipboard")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .overlay(alignment: .top) {
            if showCopied {
                Text("Copied!")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.green.opacity(0.9))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 4)
            }
        }
        .onAppear {
            titleText = prompt.title
            contentText = prompt.content
        }
        .onChange(of: titleText) { _, newValue in
            if prompt.title_ != newValue {
                prompt.title_ = newValue
                prompt.updatedAt_ = Date()
            }
        }
        .onChange(of: contentText) { _, newValue in
            if prompt.content_ != newValue {
                prompt.content_ = newValue
                prompt.updatedAt_ = Date()
            }
        }
    }
}

struct PromptDetailEmptyView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Select a Prompt")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Choose a prompt from the list or create a new one with ⌘N.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Detail") {
    let controller = PersistenceController.preview
    let context = controller.container.viewContext
    let request = NSFetchRequest<PromptEntity>(entityName: "PromptEntity")
    let prompts = try! context.fetch(request)
    return PromptDetailView(
        prompt: prompts.first!,
        viewModel: PromptListViewModel(context: context),
        categoryVM: CategoryViewModel(context: context)
    )
    .environment(\.managedObjectContext, context)
    .frame(width: 500, height: 600)
}

#Preview("Empty") {
    PromptDetailEmptyView()
        .frame(width: 500, height: 600)
}
