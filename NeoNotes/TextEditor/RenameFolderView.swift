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

struct HoverEffectView<Content: View>: View {
    let content: (Bool) -> Content
    @State private var isHovered = false
    
    init(@ViewBuilder content: @escaping (Bool) -> Content) {
        self.content = content
    }
    
    var body: some View {
        content(isHovered)
//            .background(isHovered ? Color.gray.opacity(0.2) : Color.clear)
//            .clipShape(Capsule())
//            .shadow(color: isHovered ? Color.gray.opacity(0.5) : Color.clear, radius: 3)
//            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut, value: isHovered)
            .onHover { over in
                isHovered = over
            }
    }
}

