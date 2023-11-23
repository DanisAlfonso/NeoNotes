//
//  FlashcardsStudyView.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 22.11.23.
//

import SwiftUI

struct FlashcardsStudyView: View {
    @ObservedObject var category: Category
    @State private var currentFlashcardIndex = 0
    @State private var showAnswer = false

    var body: some View {
        VStack {
            let flashcards = category.flashcardsArray
            if flashcards.count > 0 {
                let flashcard = flashcards[currentFlashcardIndex]

                VStack {
                    Text(flashcard.question ?? "No content")
                        .font(.title)
                        .padding()

                    Button("Show Answer") {
                        showAnswer.toggle()
                    }

                    if showAnswer {
                        Text(flashcard.answer ?? "No answer")
                            .font(.body)
                            .padding()
                    }
                }
                .padding()

                HStack {
                    Button("I didn't know") {
                        // Logic for incorrect answer
                        moveToNextFlashcard()
                    }
                    .padding()

                    Button("I knew it") {
                        // Logic for correct answer
                        moveToNextFlashcard()
                    }
                    .padding()
                }
            } else {
                Text("No flashcards in this category.")
            }
        }
        .navigationTitle("Studying: \(category.name ?? "Unknown")")
    }

    private func moveToNextFlashcard() {
        showAnswer = false
        let flashcards = category.flashcardsArray
        if currentFlashcardIndex < flashcards.count - 1 {
            currentFlashcardIndex += 1
        } else {
            // Reset or finish the study session
            currentFlashcardIndex = 0
        }
    }
}

extension Category {
    var flashcardsArray: [Flashcard] {
        let set = flashcards as? Set<Flashcard> ?? []
        return set.sorted { $0.creationDate ?? Date() < $1.creationDate ?? Date() }
    }
}
