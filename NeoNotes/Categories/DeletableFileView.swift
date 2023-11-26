//
//  DeletableFileView.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 25.11.23.
//

import SwiftUI
import AVFoundation

struct DeletableFileView: View {
    @State private var isHovering = false
    @State var isPlaying = false
    var filename: String
    var onDelete: () -> Void
    var onPlay: () -> Void
    
    var body: some View {
        HStack {
            Text(filename)
                .padding(.leading, 5)
            Spacer()
            if isHovering {
                Button(action: {
                    self.isPlaying.toggle()
                    onPlay()
                }) {
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 5)
                
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 5)
            }
        }
        .frame(height: 30)
        .padding(.horizontal, 5)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)))
        .onHover { hovering in
            self.isHovering = hovering
        }
    }
}

