//
//  CategoriesView.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 22.11.23.
//

import SwiftUI
import CoreData
import AVFoundation
import UniformTypeIdentifiers

struct CategoriesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var deck: Deck  // Pass the selected Deck to this view
    @State private var showingAddFlashcard = false

    var body: some View {
        List {
            ForEach(deck.categoriesArray, id: \.self) { category in
                NavigationLink(destination: FlashcardsStudyView(category: category)) {
                    Text(category.name ?? "Untitled")
                }
            }
            .onDelete(perform: deleteCategories)
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

    private func deleteCategories(offsets: IndexSet) {
        // Implement deletion logic for categories
    }
}

struct AddFlashcardView: View {
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    var deck: Deck
    @State private var flashcardContent = ""
    @State private var flashcardAnswer = ""
    @State private var categoryName = ""
    
    @State private var isHoveringQuestion = false
    @State private var isHoveringAnswer = false
    
    @State private var questionAudioURL: URL?
    @State private var answerAudioURL: URL?

    var body: some View {
        VStack {
            TextField("Category", text: $categoryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            HStack {
                TextField("Question", text: $flashcardContent)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    uploadAudio(for: .question)
                }) {
                    Image(systemName: "waveform.and.mic")
                        .foregroundColor(isHoveringQuestion ? .blue : .gray)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 10)
                .onHover { hovering in
                    isHoveringQuestion = hovering
                }
            }
            .padding()
            
            HStack {
                TextField("Answer", text: $flashcardAnswer)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    uploadAudio(for: .answer)
                }) {
                    Image(systemName: "waveform.and.mic")
                        .foregroundColor(isHoveringAnswer ? .blue : .gray)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 10)
                .onHover { hovering in
                    isHoveringAnswer = hovering
                }
            }
            .padding()
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .padding()
                .buttonStyle(.bordered)

                Button("Save") {
                    addFlashcard()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }

    private func addFlashcard() {
        let newFlashcard = Flashcard(context: viewContext)
        newFlashcard.id = UUID() // Set a new UUID for the id
        newFlashcard.creationDate = Date() // Set the current date for creationDate
        newFlashcard.question = flashcardContent
        newFlashcard.answer = flashcardAnswer

        // Find or create the category
        let category = findOrCreateCategory(named: categoryName, in: deck)
        newFlashcard.category = category

        do {
            try viewContext.save()
        } catch {
            // Handle errors
            print("Error saving context: \(error)")
        }
        
        if let questionURL = questionAudioURL {
            let filename = saveAudioFile(questionURL)
            newFlashcard.questionAudioFilename = filename
        }
        
        if let answerURL = answerAudioURL {
            let filename = saveAudioFile(answerURL)
            newFlashcard.answerAudioFilename = filename
        }
    }

    private func findOrCreateCategory(named name: String, in deck: Deck) -> Category {
        if let category = deck.categoriesArray.first(where: { $0.name == name }) {
            return category
        } else {
            let newCategory = Category(context: viewContext)
            newCategory.id = UUID() // Set a new UUID for the id
            newCategory.creationDate = Date() // Set the current date for creationDate
            newCategory.name = name
            newCategory.deck = deck
            return newCategory
        }
    }
    
    private func uploadAudio(for fieldType: FieldType) {
        #if os(iOS)
        // For iOS, you might use a document picker or audio recorder
        #elseif os(macOS)
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [
            UTType(mimeType: "audio/mpeg") ?? UTType.audio, // for mp3
            UTType(filenameExtension: "wav") ?? UTType.audio, // for wav
            UTType(mimeType: "audio/x-m4a") ?? UTType.audio, // for m4a
            UTType(mimeType: "audio/aac") ?? UTType.audio // for aac
        ]

        if panel.runModal() == .OK {
            if let pickedURL = panel.url {
                if fieldType == .question {
                    questionAudioURL = pickedURL
                } else if fieldType == .answer {
                    answerAudioURL = pickedURL
                }
            }
        }
        #endif
    }

    
    private func saveAudioFile(_ audioURL: URL) -> String {
        // Get the documents directory path
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Generate a new filename (or use the existing one)
        let newFilename = UUID().uuidString + "." + (audioURL.pathExtension)
        let destinationURL = documentsDirectory.appendingPathComponent(newFilename)
        
        do {
            // Copy the file to the new location
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: audioURL, to: destinationURL)
            return newFilename // Return the new filename
        } catch {
            print("Error saving audio file: \(error)")
            return "" // Return an empty string or handle the error appropriately
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

enum FieldType {
    case question
    case answer
}
