//
//  FlashcardsStudyView.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 22.11.23.
//

import SwiftUI
import CoreData

struct FlashcardsStudyView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var currentFlashcard: Flashcard?
    var category: Category

    let fsrsEngine = FSRS()

    var body: some View {
        VStack {
            if let flashcard = currentFlashcard {
                Text(flashcard.question ?? "No Question")

                HStack {
                    Button("Again") { rateFlashcard(rating: .Again) }
                    Button("Hard")  { rateFlashcard(rating: .Hard)  }
                    Button("Good")  { rateFlashcard(rating: .Good)  }
                    Button("Easy")  { rateFlashcard(rating: .Easy)  }
                }
            } else {
                Text("No flashcards to review.")
            }
        }
        .onAppear {
            loadNextFlashcard(from: category)
        }
    }

    private func loadNextFlashcard(from category: Category) {
        let currentDate = Date()

        // Fetch the next due flashcard
        if let nextFlashcard = category.flashcardsArray.first(where: { flashcard in
            // Assuming 'due' is a Date and flashcards are due when 'due' <= currentDate
            // This logic might change based on your app's specific requirements
            (flashcard.due ?? currentDate) <= currentDate
        }) {
            self.currentFlashcard = nextFlashcard
        } else {
            self.currentFlashcard = nil
        }
    }

    private func rateFlashcard(rating: Rating) {
        guard let flashcard = currentFlashcard else { return }
        let card = flashcard.toCard()

        // Use FSRS engine to update the card based on the rating
        let updatedCardInfo = fsrsEngine.repeat(card: card, now: Date())

        // Choose the updated card based on the rating
        if let updatedCard = updatedCardInfo[rating]?.card {
            flashcard.updateFromCard(updatedCard)
            saveContext()

            loadNextFlashcard(from: category)
        }
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            // Handle the error
        }
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

extension Category {
    var flashcardsArray: [Flashcard] {
        let set = flashcards as? Set<Flashcard> ?? []
        return set.sorted { $0.creationDate ?? Date() < $1.creationDate ?? Date() }
    }
}

struct FlashcardsStudyView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController(inMemory: true).container.viewContext
        let newCategory = Category(context: context)
        newCategory.name = "Sample Category"

        // Add some sample flashcards to the category
        let flashcard1 = Flashcard(context: context)
        flashcard1.question = "1 + 1"
        flashcard1.answer = "2"
        flashcard1.category = newCategory

        let flashcard2 = Flashcard(context: context)
        flashcard2.question = "2 + 2"
        flashcard2.answer = "4"
        flashcard2.category = newCategory

        return FlashcardsStudyView(category: newCategory)
            .environment(\.managedObjectContext, context)
            .frame(width: 400, height: 400)
    }
}

