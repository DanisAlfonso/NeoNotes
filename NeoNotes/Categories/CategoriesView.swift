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
    @State private var isHovering = false
    @State private var isNameHovering = false


    var body: some View {
        HStack {
            NavigationLink(destination: FlashcardsListView(category: category)) {
                HStack {
                    Image(systemName: "book.closed")
                        .foregroundColor(.accentColor)
                    Text(category.name ?? "Untitled")
                        .fontWeight(.medium)
                        .padding(3)
                        .background(isNameHovering ? Color.gray.opacity(0.2) : Color.clear)
                        .cornerRadius(5)
                    
                    Spacer()
                    Text("\(category.flashcardsArray.count) cards")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .onHover { hovering in
                    isNameHovering = hovering
                }

            }
            .buttonStyle(PlainButtonStyle())
            
            Button("Study now") {
                navigateToStudy = true
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(8)
            .background(isHovering ? Color.accentColor : Color.clear)
            .foregroundColor(isHovering ? Color.white : Color.accentColor)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 8) // You can adjust the corner radius
                    .stroke(isHovering ? Color.accentColor : Color.clear, lineWidth: 1) // Adjust line width for subtlety
            )
            .onHover { hovering in
                isHovering = hovering
            }
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

extension Flashcard {
    func toCard() -> Card {
        let card = Card()
        // Map Flashcard properties to Card properties
        card.due = self.due ?? Date() // Provide a default value if `self.due` is nil
        card.difficulty = self.difficulty
        card.stability = self.stability
        card.reps = Int(self.reps)
        card.lapses = Int(self.lapses)
        card.status = Status(rawValue: Int(self.status)) ?? .New
        card.lastReview = self.lastReview ?? Date()
        return card
    }

    func updateFromCard(_ card: Card) {
        // Map Card properties back to Flashcard
        self.due = card.due // 'card.due' is non-optional, so direct assignment is fine
        self.difficulty = card.difficulty
        self.stability = card.stability
        self.reps = Int16(card.reps)
        self.lapses = Int16(card.lapses)
        self.status = Int16(card.status.rawValue)
        self.lastReview = card.lastReview
    }
}
