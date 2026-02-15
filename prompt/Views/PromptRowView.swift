import SwiftUI

struct PromptRowView: View {
    @ObservedObject var prompt: PromptEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(prompt.title.isEmpty ? "Untitled" : prompt.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                if prompt.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                        .accessibilityLabel("Favorited")
                }
            }

            if !prompt.contentPreview.isEmpty {
                Text(prompt.contentPreview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack {
                if let category = prompt.category {
                    Label(category.name, systemImage: category.icon)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary)
                        .clipShape(Capsule())
                }

                Spacer()

                Text(prompt.updatedAt.relativeFormatted)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(prompt.title), \(prompt.categoryName), updated \(prompt.updatedAt.relativeFormatted)")
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let request = NSFetchRequest<PromptEntity>(entityName: "PromptEntity")
    let prompts = try! context.fetch(request)
    return List {
        ForEach(prompts, id: \.objectID) { prompt in
            PromptRowView(prompt: prompt)
        }
    }
    .frame(width: 300, height: 400)
}
