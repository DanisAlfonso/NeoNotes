//
//  NeoNotesApp.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 21.11.23.
//

import SwiftUI
import CoreData

@main
struct NeoNotesApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(viewModel)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Deck") {
                    viewModel.createNewDeck()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "NeoNotesModel")

        // Set the options for the persistent store directly
        if let description = container.persistentStoreDescriptions.first {
            description.setOption(NSNumber(value: true), forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(NSNumber(value: true), forKey: NSInferMappingModelAutomaticallyOption)
        }
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // Handle the error appropriately
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}

extension PersistenceController {
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        // Create mock data here if needed

        return controller
    }()
}

class AppViewModel: ObservableObject {
    @Published var showingAddDeck = false

    func createNewDeck() {
        showingAddDeck = true
    }
}
