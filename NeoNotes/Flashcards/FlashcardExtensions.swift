//
//  FlashcardExtensions.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 01.12.23.
//

import SwiftUI
import CoreData

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
