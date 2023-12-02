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
    @State private var hoveringAddFolder = false
    @State private var hoveringDecks = false
    @State private var hoveringStatistics = false
    @State private var hoveringSettings = false
    @State private var hoveringTodo = false
    @State private var hoveringTrash = false

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
                    .foregroundColor(hoveringDecks ? .accentColor : .primary)

                
            }
            .onHover { over in
                hoveringDecks = over
            }
            .animation(.easeInOut, value: hoveringDecks)
            
            NavigationLink(destination: StatisticsView()) {
                Label("Statistics", systemImage: "chart.bar")
                    .foregroundColor(hoveringStatistics ? .accentColor : .primary)
            }
            .onHover { over in
                hoveringStatistics = over
            }
            .animation(.easeInOut, value: hoveringStatistics)
            
            NavigationLink(destination: SettingsView()) {
                Label("Settings", systemImage: "gear")
                    .foregroundColor(hoveringSettings ? .accentColor : .primary)
            }
            .onHover { over in
                hoveringSettings = over
            }
                    
            Section(header: Text("Notes")) {
                Button(action: {
                    showingAddFolderSheet = true
                }) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                            .foregroundColor(hoveringAddFolder ? .accentColor : .gray)
                        Text("Add Folder")
                            .foregroundColor(hoveringAddFolder ? .accentColor : .primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(BorderlessButtonStyle())
                .onHover { over in
                    hoveringAddFolder = over
                }
                .animation(.easeInOut, value: hoveringAddFolder)
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
                        .foregroundColor(hoveringTodo ? .accentColor : .primary)
                }
                .onHover { over in
                    hoveringTodo = over
                }
                NavigationLink(destination: Text("Trash View Placeholder")) {
                    Label("Trash", systemImage: "trash")
                        .foregroundColor(hoveringTrash ? .accentColor : .primary)
                }
                .onHover { over in
                    hoveringTrash = over
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
