//
//  CategoriesView.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 22.11.23.
//

import SwiftUI
import CoreData

struct CategoriesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var deck: Deck  // Pass the selected Deck to this view
    @State private var showingAddFlashcard = false

    var body: some View {
        List {
            ForEach(deck.categoriesArray, id: \.self) { category in
                NavigationLink(destination: FlashcardsStudyView(category: category)) {
                    Text(category.name ?? "Untitled")
                }
            }
            .onDelete(perform: deleteCategories)
        }
        .navigationTitle("Categories in \(deck.name ?? "Deck")")
        .toolbar {
            ToolbarItem(placement: .automatic) { // Use 'automatic' for macOS
                Button(action: {
                    showingAddFlashcard.toggle()
                }) {
                    Label("Add Flashcard", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddFlashcard) {
            // Present a view to add a new flashcard
            AddFlashcardView(isPresented: $showingAddFlashcard, deck: deck)
        }
    }

    private func deleteCategories(offsets: IndexSet) {
        // Implement deletion logic for categories
    }
}


// Extend Deck to have a computed property to convert categories Set to Array
extension Deck {
    var categoriesArray: [Category] {
        let set = categories as? Set<Category> ?? []
        return set.sorted { $0.name ?? "" < $1.name ?? "" }
    }
    
    // Assume a default category for simplicity; replace with appropriate logic
    var defaultCategory: Category? {
        categoriesArray.first
    }
}

