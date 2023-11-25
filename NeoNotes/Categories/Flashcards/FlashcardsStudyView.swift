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
    @State private var triggerViewUpdate: Bool = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isFlipped = false
    @State private var isEditing = false
    @ObservedObject var viewModel = FlashcardViewModel(context: PersistenceController.shared.container.viewContext)
    
    var category: Category
    let fsrsEngine = FSRS()
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Flashcard.due, ascending: true)],
        animation: .default)
    private var flashcards: FetchedResults<Flashcard>

    var body: some View {
        VStack {
            if let flashcard = flashcards.first(where: { $0.category == category && ($0.due ?? Date()) <= Date() }) {
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
                
                if let _ = viewModel.flashcard {
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
        .sheet(isPresented: $isEditing) {
            EditFlashcardView(viewModel: viewModel)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    isEditing.toggle()
                }) {
                    Label("Edit", systemImage: "pencil")
                }
                .disabled(flashcards.first(where: { $0.category == category }) == nil)
            }
        }
        .onAppear {
            loadNextFlashcard(from: category)
        }
    }

    private func loadNextFlashcard(from category: Category) {
        let currentDate = Date()
        if let nextFlashcard = category.flashcardsArray.first(where: { $0.due ?? currentDate <= currentDate }) {
            viewModel.flashcard = nextFlashcard
        } else {
            viewModel.flashcard = nil
        }
    }

    private func rateFlashcard(rating: Rating) {
        guard let flashcard = viewModel.flashcard else { return }
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
    @State private var isHovered = false

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
                .shadow(radius: isHovered ? 7 : 5)
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

struct EditFlashcardView: View {
    @ObservedObject var viewModel: FlashcardViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var question: String = ""
    @State private var answer: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Question")) {
                    TextField("Enter question", text: $question)
                }
                Section(header: Text("Answer")) {
                    TextField("Enter answer", text: $answer)
                }
            }
            .navigationTitle("Edit Flashcard")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button("Save") {
                        viewModel.updateFlashcard(question: question, answer: answer)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                if let flashcard = viewModel.flashcard {
                    question = flashcard.question ?? ""
                    answer = flashcard.answer ?? ""
                }
            }
        }
    }
}

class FlashcardViewModel: ObservableObject {
    @Published var flashcard: Flashcard?
    private var viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }

    func loadFlashcard(withID id: UUID) {
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            let results = try viewContext.fetch(request)
            DispatchQueue.main.async {
                self.flashcard = results.first
            }
        } catch {
            print("Error fetching flashcard: \(error)")
        }
    }

    func saveFlashcard() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error.localizedDescription)")
        }
    }

    func updateFlashcard(question: String, answer: String) {
        flashcard?.question = question
        flashcard?.answer = answer
        saveFlashcard()
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