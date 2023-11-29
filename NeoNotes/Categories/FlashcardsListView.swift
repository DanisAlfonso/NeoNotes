//
//  FlashcardsListView.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 29.11.23.
//

import SwiftUI

struct FlashcardsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest var flashcards: FetchedResults<Flashcard>
    var category: Category

    init(category: Category) {
        self.category = category
        self._flashcards = FetchRequest<Flashcard>(
            entity: Flashcard.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "category == %@", category)
        )
    }

    var body: some View {
        List {
            ForEach(flashcards, id: \.self) { flashcard in
                FlashcardView(flashcard: flashcard)
            }
            .onDelete(perform: deleteFlashcard)
        }
        .navigationTitle("Flashcards in \(category.name ?? "Category")")
    }

    private func deleteFlashcard(at offsets: IndexSet) {
        for index in offsets {
            let flashcard = flashcards[index]
            viewContext.delete(flashcard)
        }

        do {
            try viewContext.save()
        } catch {
            // Handle the error appropriately
            print("Error deleting flashcard: \(error.localizedDescription)")
        }
    }
}

struct FlashcardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let flashcard: Flashcard
    @State private var showAnswer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.blue)
                Text(flashcard.question ?? "Untitled")
                    .fontWeight(.bold)
            }
            
            if showAnswer {
                HStack {
                    Image(systemName: "bubble.right")
                        .foregroundColor(.green)
                    Text(flashcard.answer ?? "No answer")
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity)
            }
        }
        .padding()
        .onTapGesture {
            withAnimation {
                showAnswer.toggle()
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                deleteFlashcard(flashcard)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func deleteFlashcard(_ flashcard: Flashcard) {
        viewContext.delete(flashcard)
        try? viewContext.save()
    }
}
