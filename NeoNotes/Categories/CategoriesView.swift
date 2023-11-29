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
        NavigationStack {
            List {
                ForEach(deck.categoriesArray, id: \.self) { category in
                    CategoryRow(category: category)
                    .contextMenu {
                        Button(action: {
                            deleteCategory(category)
                        }) {
                            Label("Delete \(category.name ?? "Category")", systemImage: "trash")
                        }
                    }
                }
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
    }
    
    private func deleteCategory(_ category: Category) {
        withAnimation {
            viewContext.delete(category)
            do {
                try viewContext.save()
            } catch {
                // Handle the error appropriately
                print("Error deleting category: \(error.localizedDescription)")
            }
        }
    }
}

struct CategoryRow: View {
    var category: Category
    @State private var navigateToStudy = false

    var body: some View {
        HStack {
            NavigationLink(destination: FlashcardsListView(category: category)) {
                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(.accentColor)
                    Text(category.name ?? "Untitled")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(category.flashcardsArray.count) cards")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Button("Study now") {
                navigateToStudy = true
            }
            .buttonStyle(BorderlessButtonStyle())
            // Navigation for "Study now" button
            NavigationLink(destination: FlashcardsStudyView(category: category), isActive: $navigateToStudy) {
                EmptyView()
            }
            .hidden()
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

extension Category {
    var flashcardsArray: [Flashcard] {
        let set = flashcards as? Set<Flashcard> ?? []
        return set.sorted { $0.creationDate ?? Date() < $1.creationDate ?? Date() }
    }
}

