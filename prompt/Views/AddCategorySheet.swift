import SwiftUI

struct AddCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var selectedIcon: String = "folder"

    var onSave: (String, String) -> Void

    private let icons = [
        "folder", "tray", "archivebox", "doc.text",
        "chevron.left.forwardslash.chevron.right", "terminal",
        "pencil", "paintbrush", "photo", "camera",
        "chart.bar", "chart.pie", "tablecells",
        "globe", "link", "envelope",
        "person", "person.2", "building.2",
        "lightbulb", "book", "graduationcap",
        "hammer", "wrench", "gearshape",
        "star", "heart", "flag",
        "tag", "bookmark", "paperclip",
        "mic", "music.note", "play.rectangle"
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("New Category")
                .font(.headline)

            TextField("Category name", text: $name)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Category name")

            VStack(alignment: .leading, spacing: 8) {
                Text("Icon")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.fixed(36)), count: 8), spacing: 8) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                        } label: {
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .frame(width: 32, height: 32)
                                .background(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(icon)
                    }
                }
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    onSave(name.trimmingCharacters(in: .whitespaces), selectedIcon)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 340)
    }
}

#Preview {
    AddCategorySheet { name, icon in
        print("Created: \(name) with icon \(icon)")
    }
}
