//
//  AddFlashcardView.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 24.11.23.
//

import SwiftUI
import CoreData
import AVFoundation
import UniformTypeIdentifiers

struct AddFlashcardView: View {
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    var deck: Deck
    @State private var flashcardQuestion = ""
    @State private var flashcardAnswer = ""
    @State private var categoryName = ""
    
    @State private var isHoveringQuestion = false
    @State private var isHoveringAnswer = false
    
    @State private var questionAudioURL: URL?
    @State private var answerAudioURL: URL?
    
    @State private var questionAudioFilename: String = ""
    @State private var answerAudioFilename: String = ""
    @State private var audioPlayer: AVAudioPlayer?

    var body: some View {
        VStack {
            TextField("Category", text: $categoryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            HStack {
                VStack {
                    Text("Question")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                    TextEditor(text: $flashcardQuestion)
                                    .frame(minHeight: 50, maxHeight: .infinity)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                                    .padding(.horizontal)
                    
                    if !questionAudioFilename.isEmpty {
                     
                        DeletableFileView(filename: questionAudioFilename, onDelete: {
                            deleteAudioFile(for: .question)
                        },
                        onPlay: {
                            if let url = questionAudioURL {
                                playAudio(url: url)
                            } else {
                                print("No URL set for question audio")
                            }
                        })
                    }
                }
                
                Button(action: {
                    print("Upload button tapped for question audio")
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
                VStack {
                    Text("Answer")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                    TextEditor(text: $flashcardAnswer)
                        .frame(minHeight: 50, maxHeight: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .padding(.horizontal)
                    
                    if !answerAudioFilename.isEmpty {
                        DeletableFileView(filename: answerAudioFilename, onDelete: {
                            deleteAudioFile(for: .answer)
                        },
                        onPlay: {
                            if let url = answerAudioURL {
                                playAudio(url: url)
                            } else {
                                print("No URL set for question audio")
                            }
                        })
                    }
                }
                
                Button(action: {
                    print("Upload button tapped for question audio")
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
                    print("Save button tapped")
                    addFlashcard()
                    isPresented = false
                }
                .disabled(flashcardQuestion.isEmpty || flashcardAnswer.isEmpty)
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .padding()
        .frame(width: 600, height: 400)
    }

    private func addFlashcard() {
        print("addFlashcard method called")
        let newFlashcard = Flashcard(context: viewContext)
        newFlashcard.id = UUID()
        newFlashcard.creationDate = Date()
        newFlashcard.question = flashcardQuestion
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
            print("Attempting to save question audio file")
            let filename = saveAudioFile(questionURL)
            newFlashcard.questionAudioFilename = filename
            print("New flashcard question audio filename: \(filename)")
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
            newCategory.id = UUID()
            newCategory.creationDate = Date() 
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
                print("File selected: \(pickedURL.path)")
                let pickedFilename = pickedURL.lastPathComponent
                if fieldType == .question {
                    questionAudioURL = pickedURL
                    questionAudioFilename = pickedFilename
                    print("Question audio URL set to: \(questionAudioURL?.path ?? "nil")")
                    print("Question audio filename set to: \(questionAudioFilename)")
                } else if fieldType == .answer {
                    answerAudioURL = pickedURL
                    answerAudioFilename = pickedFilename
                    print("Answer audio URL set to: \(answerAudioURL?.path ?? "nil")")
                    print("Answer audio filename set to: \(answerAudioFilename)")
                }
            }
        }
        #endif
    }

    private func saveAudioFile(_ audioURL: URL) -> String {
        print("saveAudioFile called with URL: \(audioURL.path)")
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let newFilename = UUID().uuidString + "." + audioURL.pathExtension
        let destinationURL = documentsDirectory.appendingPathComponent(newFilename)
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: audioURL, to: destinationURL)
            print("Audio file saved from \(audioURL.path) to \(destinationURL.path)")
            return newFilename
        } catch {
            print("Error saving audio file: \(error)")
            return ""
        }
    }

    private func playAudio(filename: String? = nil, url: URL? = nil) {
        let fileURL: URL

        if let filename = filename {
            // Existing logic to play from saved files
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            fileURL = documentsDirectory.appendingPathComponent(filename)
        } else if let url = url {
            // Play from the provided URL
            fileURL = url
        } else {
            print("No audio file specified")
            return
        }

        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
                audioPlayer?.play()
                print("Audio playback started for \(fileURL.path)")
            } catch {
                print("Could not play audio. Error: \(error.localizedDescription)")
            }
        } else {
            print("Audio file does not exist at path: \(fileURL.path)")
        }
    }
    
    private func deleteAudioFile(for fieldType: FieldType) {
        switch fieldType {
        case .question:
            if let url = questionAudioURL {
                removeAudioFile(at: url)
            }
            questionAudioURL = nil
            questionAudioFilename = ""
        case .answer:
            if let url = answerAudioURL {
                removeAudioFile(at: url)
            }
            answerAudioURL = nil
            answerAudioFilename = ""
        }
    }

    private func removeAudioFile(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            print("File removed: \(url.lastPathComponent)")
        } catch {
            print("Error removing file: \(error)")
        }
    }
    
    // Helper function to get the path to the documents directory
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

enum FieldType {
    case question
    case answer
}
