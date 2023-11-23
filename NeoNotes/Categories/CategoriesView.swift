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

struct AddFlashcardView: View {
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    var deck: Deck
    @State private var flashcardContent = ""
    @State private var flashcardAnswer = ""
    @State private var categoryName = ""

    var body: some View {
        VStack {
            TextField("Category", text: $categoryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            TextField("Content", text: $flashcardContent)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            TextField("Answer", text: $flashcardAnswer)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .padding()
                .buttonStyle(.bordered)

                Button("Save") {
                    addFlashcard()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }

    private func addFlashcard() {
        let newFlashcard = Flashcard(context: viewContext)
        newFlashcard.id = UUID() // Set a new UUID for the id
        newFlashcard.creationDate = Date() // Set the current date for creationDate
        newFlashcard.question = flashcardContent
        newFlashcard.answer = flashcardAnswer

        // Find or create the category
        let category = findOrCreateCategory(named: categoryName, in: deck)
        newFlashcard.category = category

        do {
            try viewContext.save()
        } catch {
            // Handle errors
            print("Error saving context: \(error)")
        }
    }

    private func findOrCreateCategory(named name: String, in deck: Deck) -> Category {
        if let category = deck.categoriesArray.first(where: { $0.name == name }) {
            return category
        } else {
            let newCategory = Category(context: viewContext)
            newCategory.id = UUID() // Set a new UUID for the id
            newCategory.creationDate = Date() // Set the current date for creationDate
            newCategory.name = name
            newCategory.deck = deck
            return newCategory
        }
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
