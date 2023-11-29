//
//  FlashcardsListView.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 29.11.23.
//

import SwiftUI

struct FlashcardsListView: View {
    var category: Category

    var body: some View {
        List(category.flashcardsArray, id: \.self) { flashcard in
            FlashcardView(flashcard: flashcard)
        }
        .navigationTitle("Flashcards in \(category.name ?? "Category")")
    }
}

struct FlashcardView: View {
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
    }
}
