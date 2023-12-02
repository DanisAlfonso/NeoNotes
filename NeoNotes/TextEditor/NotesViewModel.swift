//
//  NotesViewModel.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 01.12.23.
//

import Foundation
import CoreData

class NotesViewModel: ObservableObject {
    private let context: NSManagedObjectContext
    @Published var folders: [Folder] = []
    
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchFolders()
    }
    
    func fetchFolders() {
        print("Fetching folders...")
        let request: NSFetchRequest<Folder> = Folder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Folder.name, ascending: true)]
        
        DispatchQueue.main.async {
            do {
                self.folders = try self.context.fetch(request)
                print("Folders fetched successfully. Total folders: \(self.folders.count)")
            } catch {
                print("Error fetching folders: \(error)")
            }
        }
    }

    // Function to add a new folder
    func addFolder(withName name: String, parentFolderID: UUID?) {
        let folder = Folder(context: context)
        folder.id = UUID()
        folder.name = name
        
        if let parentID = parentFolderID {
            if let parentFolder = fetchFolder(withID: parentID) {
                folder.parentFolder = parentFolder
            }
        }
        
        saveContext()
        fetchFolders()
    }

    // Helper method to fetch the "Notes" root folder
    private func fetchNotesRootFolder() -> Folder? {
        let request: NSFetchRequest<Folder> = Folder.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", "Notes")
        request.fetchLimit = 1 // There should only be one "Notes" root folder
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching 'Notes' root folder: \(error)")
            return nil
        }
    }

    // Helper method to create the "Notes" root folder
    private func createNotesRootFolder() -> Folder {
        let folder = Folder(context: context)
        folder.id = UUID()
        folder.name = "Notes"
        saveContext()
        return folder
    }

    // Function to delete a folder and its contents
    func deleteFolder(_ folder: Folder) {
        context.delete(folder)
        saveContext()
        fetchFolders() // Refresh the folder list after deleting the folder
    }
    
    // Helper function to fetch a folder by ID
    private func fetchFolder(withID id: UUID) -> Folder? {
        let request: NSFetchRequest<Folder> = Folder.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1 // We're fetching a specific folder by ID
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching folder with ID \(id): \(error)")
            return nil
        }
    }
    
    func renameFolder(_ folder: Folder, to newName: String) {
        print("Attempting to rename folder: \(folder.name ?? "Unnamed") to \(newName)")
        folder.name = newName
        
        print("Folder renamed. Now refreshing folder list.")

        saveContext()
        DispatchQueue.main.async {
            self.fetchFolders()
        }
    }

    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
                print("Context saved successfully.")
            } catch {
                // Handle the error appropriately
                print("Error saving context: \(error)")
            }
        }
    }
}
