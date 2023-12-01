//
//  EditorView.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 01.12.23.
//

import SwiftUI

struct EditorView: View {
    @State private var markdownText: String = ""

    var body: some View {
        TextEditor(text: $markdownText)
            .border(Color.gray, width: 1)
            .padding()
    }
}

struct AddFolderView: View {
    @Binding var isPresented: Bool
    @ObservedObject var notesViewModel: NotesViewModel
    @State private var folderName: String = ""

    var body: some View {
        VStack {
            Text("Enter new folder name:")
            TextField("Folder Name", text: $folderName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Add") {
                    notesViewModel.addFolder(withName: folderName, parentFolderID: nil)
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(folderName.isEmpty)
            }
            .padding()
        }
        .frame(width: 300, height: 120)
        .padding()
    }
}
