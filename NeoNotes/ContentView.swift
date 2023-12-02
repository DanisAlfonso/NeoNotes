//
//  ContentView.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 21.11.23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @EnvironmentObject var notesViewModel: NotesViewModel
    @State private var showingAddFolderSheet = false
    @State private var hovering = false

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var body: some View {
        Group {
            #if os(macOS)
            NavigationSplitView(sidebar: {
                sidebar
            }, detail: {
                DecksView()
            })
            .navigationSplitViewStyle(.balanced)
            
            #else
            if horizontalSizeClass == .compact {
                iPhoneTabView()
            } else {
                iPadSidebarView()
            }
            #endif
        }
        .sheet(isPresented: $viewModel.showingAddDeck) {
            AddDeckView(isPresented: $viewModel.showingAddDeck)
        }
        .sheet(isPresented: $viewModel.showingAddFlashcard) {
            AddFlashcardView(isPresented: $viewModel.showingAddFlashcard, deck: nil)
        }
        .sheet(isPresented: $showingAddFolderSheet) {
            AddFolderView(isPresented: $showingAddFolderSheet, notesViewModel: notesViewModel)
        }
    }
    
    private var sidebar: some View {
        List {
            NavigationLink(destination: DecksView()) {
                Label("Decks", systemImage: "rectangle.stack")
            }
            
            NavigationLink(destination: StatisticsView()) {
                Label("Statistics", systemImage: "chart.bar")
            }
            
            NavigationLink(destination: SettingsView()) {
                Label("Settings", systemImage: "gear")
            }
                    
            Section(header: Text("Notes")) {
                Button(action: {
                    showingAddFolderSheet = true
                }) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                            .foregroundColor(hovering ? .accentColor : .gray)
                        Text("Add Folder")
                            .foregroundColor(hovering ? .accentColor : .primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
                }
                .buttonStyle(BorderlessButtonStyle())
                .onHover { over in
                    hovering = over // Update the state variable
                }
                .animation(.easeInOut, value: hovering)
                .padding(.top, 5)
                
                ForEach(notesViewModel.folders, id: \.self) { folder in
                    NavigationLink(destination: EditorView()) {
                        HStack {
                            Image(systemName: "folder")
                            Text(folder.name ?? "Untitled Folder")
                                .contextMenu {
                                    Button("Rename", action: { /* Implement rename action */ })
                                    Button("Delete", action: { /* Implement delete action */ })
                                    Button("Add Subfolder", action: { /* Implement add subfolder action */ })
                                }
                        }
                        .padding(.leading, 10)
                    }
                }
            
                NavigationLink(destination: Text("Todo View Placeholder")) {
                    Label("Todo", systemImage: "checkmark.circle")
                }
                NavigationLink(destination: Text("Trash View Placeholder")) {
                    Label("Trash", systemImage: "trash")
                }
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
    }
}

#if os(iOS)
struct iPhoneTabView: View {
    var body: some View {
        TabView {
            DecksView()
                .tabItem {
                    Image(systemName: "rectangle.stack")
                    Text("Flashcards")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }

            AccountView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Account")
                }
        }
    }
}

struct iPadSidebarView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Flashcards", destination: DecksView())
                NavigationLink("Settings", destination: SettingsView())
                NavigationLink("Account", destination: AccountView())
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("QuickCards")
        }
    }
}
#endif

struct AccountView: View {
    var body: some View {
        Text("Placeholder for Account")
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Placeholder for Settings")
    }
}
