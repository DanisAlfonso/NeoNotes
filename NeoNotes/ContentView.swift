//
//  ContentView.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 21.11.23.
//

import SwiftUI

import SwiftUI

struct ContentView: View {
    @State private var selection: NavigationItem = .decks
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        if sizeClass == .compact {
            iPhoneTabView(selection: $selection)
        } else {
            NavigationSplitView {
                SidebarView(selection: $selection)
            } detail: {
                navigationDestination(for: selection)
            }
        }
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

    @ViewBuilder
    private func iPhoneTabView(selection: Binding<NavigationItem>) -> some View {
        TabView(selection: selection) {
            NavigationView { // Wrap each tab content in a NavigationView
                DecksView()
            }
            .tabItem {
                Label("Decks", systemImage: "square.stack.3d.down.right")
            }
            .tag(NavigationItem.decks)

            NavigationView { // Do the same for each tab
                NotesView()
            }
            .tabItem {
                Label("Notes", systemImage: "note.text")
            }
            .tag(NavigationItem.notes)

            NavigationView { // And for Settings
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(NavigationItem.settings)
        }
    }
}

struct NotesView: View {
    var body: some View {
        Text("Notes")
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings")
    }
}
