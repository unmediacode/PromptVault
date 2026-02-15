import SwiftUI

@main
struct promptApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup("PromptVault") {
            ContentView(context: persistenceController.container.viewContext)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .defaultSize(width: 1100, height: 700)
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Prompt") {
                    NotificationCenter.default.post(name: .createNewPrompt, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(after: .pasteboard) {
                Button("Copy Prompt Content") {
                    NotificationCenter.default.post(name: .copySelectedPrompt, object: nil)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }

            CommandGroup(after: .textEditing) {
                Button("Find Prompt") {
                    NotificationCenter.default.post(name: .focusSearch, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("Delete Prompt") {
                    NotificationCenter.default.post(name: .deleteSelectedPrompt, object: nil)
                }
                .keyboardShortcut(.delete, modifiers: .command)
            }
        }
    }
}
