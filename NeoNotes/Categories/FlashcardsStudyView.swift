//
//  FlashcardsStudyView.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 22.11.23.
//

import SwiftUI
import CoreData
import AVFoundation

struct FlashcardsStudyView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var currentFlashcard: Flashcard?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isFlipped = false
    var category: Category

    let fsrsEngine = FSRS()

    var body: some View {
        VStack {
            if let flashcard = currentFlashcard {
                ZStack {
                    if !isFlipped {
                        VStack {
                            Text(flashcard.question ?? "No Question")
                                .font(.title)
                                .foregroundStyle(.black)
                            
                            if let questionAudioFilename = flashcard.questionAudioFilename, !questionAudioFilename.isEmpty {
                                let fileURL = getDocumentsDirectory().appendingPathComponent(questionAudioFilename)
                                if FileManager.default.fileExists(atPath: fileURL.path) {
                                    playButton(for: questionAudioFilename, isFlipped: isFlipped)
                                }
                            }
                        }
                    }
                    if isFlipped {
                        VStack {
                            Text(flashcard.answer ?? "No Answer")
                                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                                .font(.title)
                                .foregroundStyle(.black)
                            
                            // Play button for answer audio
                            if let answerAudioFilename = flashcard.answerAudioFilename, !answerAudioFilename.isEmpty {
                                let fileURL = getDocumentsDirectory().appendingPathComponent(answerAudioFilename)
                                if FileManager.default.fileExists(atPath: fileURL.path) {
                                    playButton(for: answerAudioFilename, isFlipped: isFlipped)
                                }
                            }
                        }
                    }
                }
                .frame(width: 600, height: 400)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .onTapGesture {
                    withAnimation {
                        isFlipped.toggle()
                    }
                }
                
                if let _ = currentFlashcard {
                    HStack {
                        Spacer(minLength: 20)
                        RatingButton(text: "Again", color: .red,    action: { rateFlashcard(rating: .Again) })
                        RatingButton(text: "Hard",  color: .orange, action: { rateFlashcard(rating: .Hard)  })
                        RatingButton(text: "Good",  color: .green,  action: { rateFlashcard(rating: .Good)  })
                        RatingButton(text: "Easy",  color: .blue,   action: { rateFlashcard(rating: .Easy)  })
                        Spacer(minLength: 20)
                    }
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

        self.isFlipped = false
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
    
    private func playAudio(filename: String) {
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.play()
        } catch {
            print("Unable to play audio: \(error)")
        }
    }
    
    @ViewBuilder
    private func playButton(for audioFilename: String, isFlipped: Bool) -> some View {
        Button(action: {
            playAudio(filename: audioFilename)
        }) {
            Image(systemName: "play.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 44)
                .foregroundStyle(.black)
                .rotationEffect(.degrees(isFlipped ? 180 : 0))
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            playAudio(filename: audioFilename)
        }
    }
    
    // Helper function to get the path to the documents directory
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

struct RatingButton: View {
    let text: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    @State private var isHovered = false // State to track if the mouse is hovering

    var body: some View {
        Button(action: {
            self.isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isPressed = false
                self.action()
            }
        }) {
            Text(text)
                .fontWeight(.bold)
                .padding(.vertical, 13)
                .padding(.horizontal, 15)
                .frame(minWidth: 0, maxWidth: .infinity)
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(5)
                .shadow(radius: isHovered ? 7 : 5) // Adjust shadow based on hover state
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut, value: isPressed)
        .onHover { hovering in
            self.isHovered = hovering
        }
        .opacity(isHovered ? 0.9 : 1.0)
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
        
        let flashcard3 = Flashcard(context: context)
        flashcard3.question = "3 + 3"
        flashcard3.answer = "6"
        flashcard3.category = newCategory

        return FlashcardsStudyView(category: newCategory)
            .environment(\.managedObjectContext, context)
            .frame(width: 600, height: 500)
    }
}
