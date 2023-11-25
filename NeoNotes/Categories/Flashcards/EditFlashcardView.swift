//
//  EditFlashcardView.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 25.11.23.
//

import SwiftUI

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
                        viewModel.updateFlashcard(question: question, answer: answer)
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
                }
            }
            .overlay(
                isSaving ? ProgressView("Saving...").progressViewStyle(CircularProgressViewStyle()) : nil
            )
        }
    }
}
