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

