//
//  SidebarView.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 21.11.23.
//

import SwiftUI

enum NavigationItem: String, CaseIterable {
    case decks = "Decks"
    case notes = "Notes"
    case settings = "Settings"

    var id: String { self.rawValue }
}

struct SidebarView: View {
    @Binding var selection: NavigationItem

    var body: some View {
        List {
            ForEach(NavigationItem.allCases, id: \.id) { item in
                if #available(macOS 11.0, *) {
                    // macOS specific NavigationLink
                    NavigationLink(value: item) {
                        Label(item.rawValue, systemImage: "circle")
                    }
                } else {
                    // iOS specific NavigationLink
                    NavigationLink(
                        destination: navigationDestination(for: item),
                        tag: item,
                        selection: Binding($selection) // Convert to optional binding
                    ) {
                        Label(item.rawValue, systemImage: "circle")
                    }
                }
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("NeoNotes")
    }

    @ViewBuilder
    private func navigationDestination(for item: NavigationItem) -> some View {
        switch item {
        case .decks:
            DecksView()
        case .notes:
            NotesView()
        case .settings:
            SettingsView()
        }
    }
}


