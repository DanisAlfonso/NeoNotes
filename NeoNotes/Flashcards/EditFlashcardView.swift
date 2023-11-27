//
//  EditFlashcardView.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 25.11.23.
//

import SwiftUI
import AVFoundation

struct EditFlashcardView: View {
    @ObservedObject var viewModel: FlashcardViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var question: String = ""
    @State private var answer: String = ""
    @State private var isSaving = false
    
    @State private var questionAudioURL: URL?
    @State private var answerAudioURL: URL?
    @State private var questionAudioFilename: String = ""
    @State private var answerAudioFilename: String = ""
    @State private var audioPlayer: AVAudioPlayer?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Question")
                    .padding(.leading, 20)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)) {
                    TextEditor(text: $question)
                        .frame(minHeight: 50, maxHeight: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        AudioManagementView(audioURL: $questionAudioURL,
                                            audioFilename: $questionAudioFilename,
                                            onUpload: { uploadAudio(for: .question) },
                                            onPlay: { playAudio(url: questionAudioURL) },
                                            onDelete: { deleteAudioFile(for: .question) })
                    }
            
                Section(header: Text("Answer")
                    .padding(.leading, 20)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)) {
                    TextEditor(text: $answer)
                        .frame(minHeight: 50, maxHeight: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        AudioManagementView(audioURL: $answerAudioURL,
                                            audioFilename: $answerAudioFilename,
                                            onUpload: { uploadAudio(for: .answer) },
                                            onPlay: { playAudio(url: answerAudioURL) },
                                            onDelete: { deleteAudioFile(for: .answer) })
                }
            }
            .navigationTitle("Edit Flashcard")
            .toolbar {
                ToolbarItemGroup(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItemGroup(placement: .confirmationAction) {
                    Button("Save") {
                        isSaving = true
                        viewModel.updateFlashcard(question: question, 
                                                  answer: answer,
                                                  questionAudio: questionAudioFilename.isEmpty ? nil : questionAudioFilename,
                                                  answerAudio: answerAudioFilename.isEmpty ? nil : answerAudioFilename)
                        // Delay dismissal to simulate saving time
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isSaving = false
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .disabled(question.isEmpty || answer.isEmpty || isSaving)
                }
            }
            .onAppear {
                if let flashcard = viewModel.flashcard {
                    question = flashcard.question ?? ""
                    answer = flashcard.answer ?? ""
                    
                    questionAudioFilename = flashcard.questionAudioFilename ?? ""
                    answerAudioFilename = flashcard.answerAudioFilename ?? ""
                    
                    questionAudioURL = getAudioFileURL(filename: questionAudioFilename)
                    answerAudioURL = getAudioFileURL(filename: answerAudioFilename)
                }
            }
            .overlay(
                isSaving ? ProgressView("Saving...").progressViewStyle(CircularProgressViewStyle()) : nil
            )
        }
    }
    
    // Functions for handling audio operations
    private func uploadAudio(for fieldType: FieldType) {
        let openPanel = NSOpenPanel()
        openPanel.prompt = "Select Audio File"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        if #available(macOS 12.0, *) {
            openPanel.allowedContentTypes = [
                UTType.mp3,
                UTType.wav,
                UTType.audio,
                UTType(exportedAs: "public.mpeg-4-audio") // For M4A, check if this identifier is correct for your case
            ]
        } else {
            // Fallback on earlier versions
            openPanel.allowedFileTypes = ["mp3", "m4a", "wav", "aac"]
        }
        openPanel.begin { response in
            if response == .OK, let selectedURL = openPanel.url {
                DispatchQueue.main.async {
                    switch fieldType {
                    case .question:
                        self.questionAudioURL = selectedURL
                        self.questionAudioFilename = selectedURL.lastPathComponent
                    case .answer:
                        self.answerAudioURL = selectedURL
                        self.answerAudioFilename = selectedURL.lastPathComponent
                    }
                    // Copy the file to the app's directory and save the filename in the view model
                    self.copyAudioFileToAppDirectory(from: selectedURL, for: fieldType)
                }
            }
        }
    }

    private func copyAudioFileToAppDirectory(from url: URL, for fieldType: FieldType) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)

        do {
            // Check if file exists before copying
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: url, to: destinationURL)
            
            // Update the state variables with the new file location
            DispatchQueue.main.async {
                switch fieldType {
                case .question:
                    self.questionAudioURL = destinationURL
                    self.questionAudioFilename = destinationURL.lastPathComponent
                case .answer:
                    self.answerAudioURL = destinationURL
                    self.answerAudioFilename = destinationURL.lastPathComponent
                }
            }
        } catch {
            print("Failed to copy audio file: \(error)")
        }
    }

    
    private func playAudio(url: URL?) {
        guard let url = url else {
            print("Audio URL is nil")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Failed to play audio: \(error.localizedDescription)")
        }
    }

    private func deleteAudioFile(for fieldType: FieldType) {
        // Set the appropriate state variables to nil
        switch fieldType {
        case .question:
            questionAudioURL = nil
            questionAudioFilename = ""
        case .answer:
            answerAudioURL = nil
            answerAudioFilename = ""
        }

        // Additional file system cleanup can be done here if needed
    }
    
    private func getAudioFileURL(filename: String) -> URL? {
        guard !filename.isEmpty else { return nil }
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(filename)
    }
    
}

struct AudioManagementView: View {
    @Binding var audioURL: URL?
    @Binding var audioFilename: String
    
    @State private var isHoveringPlay = false
    @State private var isHoveringTrash = false
    
    var onUpload: () -> Void
    var onPlay: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack {
            HStack {
                // Display the filename if available
                if !audioFilename.isEmpty {
                    Text(audioFilename)
                        .padding(.leading, 5)
                    Spacer()
                    Button(action: onPlay) {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(isHoveringPlay ? .blue : .gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 5)
                    .onHover { hovering in
                        isHoveringPlay = hovering
                    }

                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(isHoveringTrash ? .red : .gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 5)
                    .onHover { hovering in
                        isHoveringTrash = hovering
                    }
                } else {
                    // Show a message or leave blank if no audio file
                    Text("No audio file selected")
                        .italic()
                        .foregroundColor(.gray)
                }
            }
            .frame(height: 30)
            .padding(.horizontal, 5)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)))

            Button("Upload Audio") {
                onUpload()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 5)
        }
    }
}
