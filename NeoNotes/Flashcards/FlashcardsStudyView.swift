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
    
    @State private var currentStudySession: StudySession?
    @State private var reviewedFlashcardsCount: Int = 0
    
    @State private var countAgain: Int = 0
    @State private var countHard: Int = 0
    @State private var countGood: Int = 0
    @State private var countEasy: Int = 0



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
                
                if let flashcard = viewModel.flashcard {
                    let nextDueDates = getNextDueDates(flashcard: flashcard)
                    
                    HStack {
                        Spacer(minLength: 20)
                        ForEach([Rating.Again, Rating.Hard, Rating.Good, Rating.Easy], id: \.self) { rating in
                            if let dueDate = nextDueDates[rating] {
                                RatingButton(
                                    text: rating.description,
                                    subtitle: dueDate.formatted(), // Format the date here
                                    color: colorForRating(rating),
                                    action: { rateFlashcard(rating: rating) },
                                    shortcut: KeyEquivalent(Character(String(rating.rawValue))),
                                    tooltip: "Shortcut: \(rating.rawValue)"
                                )
                            }
                        }
                        Spacer(minLength: 20)
                    }
                }
            } else {
                Text("No flashcards to review.")
            }
        }
        .sheet(isPresented: $isEditing) {
            EditFlashcardView(viewModel: viewModel)
                .frame(minHeight: 400)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    isEditing.toggle()
                }) {
                    Label("Edit", systemImage: "pencil")
                }
                .disabled(flashcards.first(where: { $0.category == category }) == nil)
                .help("Edit Flashcard")
            }
        }
        .onAppear {
            viewModel.loadNextFlashcard(from: category)
            startStudySession()
        }
        .onDisappear {
            endStudySession()
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

            viewModel.loadNextFlashcard(from: category)
            isFlipped = false
            reviewedFlashcardsCount += 1
            
            switch rating {
                case .Again:
                    countAgain += 1
                case .Hard:
                    countHard += 1
                case .Good:
                    countGood += 1
                case .Easy:
                    countEasy += 1
            }
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
    
    func getNextDueDates(flashcard: Flashcard) -> [Rating: Date] {
        let card = flashcard.toCard()
        let fsrsEngine = FSRS()
        let schedulingInfo = fsrsEngine.repeat(card: card, now: Date())
        
        var nextDueDates: [Rating: Date] = [:]
        for (rating, info) in schedulingInfo {
            nextDueDates[rating] = info.card.due
        }
        return nextDueDates
    }
    
    func colorForRating(_ rating: Rating) -> Color {
        switch rating {
        case .Again:
            return Color.red
        case .Hard:
            return Color.orange
        case .Good:
            return Color.green
        case .Easy:
            return Color.blue
        }
    }
    
    func startStudySession() {
        let newSession = StudySession(context: viewContext)
        newSession.id = UUID()
        newSession.startTime = Date()
        currentStudySession = newSession
        reviewedFlashcardsCount = 0
    }

    func endStudySession() {
        guard let session = currentStudySession else { return }
        session.endTime = Date()
        session.duration = session.endTime?.timeIntervalSince(session.startTime ?? Date()) ?? 0
        session.cardsReviewed = Int64(reviewedFlashcardsCount)
        
        session.countAgain = Int64(countAgain)
        session.countHard = Int64(countHard)
        session.countGood = Int64(countGood)
        session.countEasy = Int64(countEasy)

        currentStudySession = nil
        reviewedFlashcardsCount = 0
        countAgain = 0
        countHard = 0
        countGood = 0
        countEasy = 0
        
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving study session: \(error)")
        }
    }
}

struct RatingButton: View {
    let text: String
    let subtitle: String? // Date string
    let color: Color
    let action: () -> Void
    let shortcut: KeyEquivalent
    let tooltip: String
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
            VStack {
                Text(text)
                    .fontWeight(.bold)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(5)
            .shadow(radius: isHovered ? 7 : 5)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .keyboardShortcut(shortcut, modifiers: [])
        .help(tooltip)
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

class FlashcardViewModel: ObservableObject {
    @Published var flashcard: Flashcard?
    private var viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    func loadNextFlashcard(from category: Category) {
        let currentDate = Date()
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@ AND due <= %@", category, currentDate as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Flashcard.due, ascending: true)]
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            if let flashcard = results.first {
                DispatchQueue.main.async {
                    self.flashcard = flashcard
                }
            } else {
                DispatchQueue.main.async {
                    self.flashcard = nil
                }
            }
        } catch {
            print("Error fetching flashcards: \(error)")
        }
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

    func updateFlashcard(question: String, answer: String, questionAudio: String?, answerAudio: String?) {
        print("Updating flashcard with question: \(question), answer: \(answer)")
        flashcard?.question = question
        flashcard?.answer = answer
        flashcard?.questionAudioFilename = questionAudio ?? ""
        flashcard?.answerAudioFilename = answerAudio ?? ""
        
        if questionAudio == nil {
            deleteAudioFromDocuments(filename: flashcard?.questionAudioFilename)
        }
        if answerAudio == nil {
            deleteAudioFromDocuments(filename: flashcard?.answerAudioFilename)
        }
        saveFlashcard()
    }
    
    private func deleteAudioFromDocuments(filename: String?) {
        guard let filename = filename, !filename.isEmpty else { return }
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            print("Failed to delete audio file: \(error.localizedDescription)")
        }
    }
}
