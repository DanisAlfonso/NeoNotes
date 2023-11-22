//
//  ContentView.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 21.11.23.
//

import SwiftUI

struct ContentView: View {
    @State private var isSidebarVisible = true
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var body: some View {
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
    
    private var sidebar: some View {
        List {
            NavigationLink(destination: DecksView()) {
                Label("Decks", systemImage: "rectangle.stack")
            }
            NavigationLink(destination: SettingsView()) {
                Label("Settings", systemImage: "gear")
            }
            NavigationLink(destination: AccountView()) {
                Label("Account", systemImage: "person.crop.circle")
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
    }
    
    private func toggleSidebar() {
        isSidebarVisible.toggle()
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
        Text("Account")
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings")
    }
}
