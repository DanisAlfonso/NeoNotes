//
//  DecksView.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 21.11.23.
//

import SwiftUI
import CoreData

struct DecksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddDeck = false
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Deck.creationDate, ascending: true)],
        animation: .default)
    private var decks: FetchedResults<Deck>

    var body: some View {
    let columns = [
        GridItem(.flexible(minimum: 160)),
        GridItem(.flexible(minimum: 160))
    ]

        ScrollView {
            LazyVGrid(columns: columns, spacing: 30) {
                ForEach(decks) { deck in
                    DeckCardView(deck: deck)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Decks")
        .toolbar {
            ToolbarItem(placement: .automatic) { // For macOS
                Button(action: {
                    showingAddDeck.toggle()
                }) {
                    Label("Add Deck", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddDeck) {
            AddDeckView(isPresented: $showingAddDeck)
        }
    }
}

struct AddDeckView: View {
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @State private var deckName = ""

    var body: some View {
            VStack {
                HStack {
                    Text("New Deck")
                        .font(.headline)
                        .padding()
                }

                Divider()

                TextField("Deck Name", text: $deckName)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                HStack {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .padding()
                    .buttonStyle(.bordered)
                    
                    Button("Save") {
                        addNewDeck()
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
            .frame(width: 300, height: 200)
            .padding()
        }

    private func addNewDeck() {
        withAnimation {
            let newDeck = Deck(context: viewContext)
            newDeck.id = UUID()
            newDeck.name = deckName
            newDeck.creationDate = Date()

            do {
                try viewContext.save()
            } catch {
                // Handle the error appropriately
            }
        }
    }
}

struct DeckCardView: View {
    let deck: Deck
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading) {
            Text(deck.name ?? "Untitled")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding([.top, .horizontal])
            Spacer()
            HStack {
                Text("Study now")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    // Perform an action, like navigating to the deck details
                }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.white)
                        .imageScale(.large)
                }
            }
            .padding([.bottom, .horizontal])
        }
        .frame(minHeight: 180)
        .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .scaleEffect(isHovered ? 1.04 : 1.0) // Scale the card slightly when hovered
            .animation(.easeInOut(duration: 0.2), value: isHovered) // Animate the scale effect
            .onHover { hover in
                isHovered = hover
            }
        .padding()
        .contextMenu {
            Button(action: {
                deleteDeck(deck)
            }) {
                Label("Delete \(deck.name ?? "Deck")", systemImage: "trash")
            }
        }
    }
    
    private func deleteDeck(_ deck: Deck) {
        withAnimation {
            viewContext.delete(deck)
            
            do {
                try viewContext.save()
            } catch {
                // Handle the error appropriately
                print(error.localizedDescription)
            }
        }
    }
}
