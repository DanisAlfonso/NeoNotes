//
//  FlashcardViewModel.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 01.12.23.
//

import SwiftUI
import CoreData

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
