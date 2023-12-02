//
//  RenameFolderView.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 02.12.23.
//

import SwiftUI

struct RenameFolderView: View {
    @Binding var isPresented: Bool
    @Binding var folderName: String
    let onRename: (String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Rename Folder")
                .font(.headline)
            
            TextField("New name", text: $folderName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                Button("Save") {
                    onRename(folderName)
                    isPresented = false
                }
            }
        }
        .padding()
        .frame(width: 300)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 1)
        )
    }
}


