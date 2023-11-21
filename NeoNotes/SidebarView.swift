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
    var systemImageName: String {
        switch self {
        case .decks:
            return "rectangle.stack" // Example icon for Decks
        case .notes:
            return "note.text" // Example icon for Notes
        case .settings:
            return "gear" // Example icon for Settings
        }
    }
}

struct SidebarView: View {
    @Binding var selection: NavigationItem

    var body: some View {
        List {
            ForEach(NavigationItem.allCases, id: \.id) { item in
                if #available(macOS 11.0, *) {
                    NavigationLink(value: item) {
                        Label(item.rawValue, systemImage: item.systemImageName)
                    }
                } else {
                    NavigationLink(
                        destination: navigationDestination(for: item),
                        tag: item,
                        selection: Binding($selection)
                    ) {
                        Label(item.rawValue, systemImage: item.systemImageName)
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
