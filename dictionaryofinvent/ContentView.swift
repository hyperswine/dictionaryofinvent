//
//  ContentView.swift
//  dictionaryofinvent
//
//  Created by Jason Qin on 2025-05-18.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Sort alphabetically by title; change to `createdAt` if you prefer chronological.
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Invention.title, ascending: true)],
        animation: .default)
    private var inventions: FetchedResults<Invention>

    @State private var searchText = ""

    // Grid definition for the detail pane
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 260), spacing: 16)
    ]

    var body: some View {
        NavigationSplitView {
            // Sidebar list – searchable
            List {
                ForEach(filtered) { inv in
                    NavigationLink(value: inv.objectID) {
                        Text(inv.title ?? "Untitled")
                    }
                }
                .onDelete(perform: delete)
            }
            .searchable(text: $searchText, prompt: "Search inventions…")
            .navigationTitle("Inventions")
            .toolbar {
                ToolbarItem {
                    Button { add() } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
        } detail: {
            // Grid of cards showing (filtered) inventions
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filtered) { inv in
                        EntryCard(invention: inv)
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Helpers
    private var filtered: [Invention] {
        guard !searchText.isEmpty else { return Array(inventions) }
        let q = searchText.lowercased()
        return inventions.filter {
            ($0.title ?? "").lowercased().contains(q) ||
            ($0.details ?? "").lowercased().contains(q)
        }
    }

    private func add() {
        let new = Invention(context: viewContext)
        new.title = "New invention"
        new.details = ""
        new.createdAt = .now
        try? viewContext.save()
    }

    private func delete(_ offsets: IndexSet) {
        offsets.map { filtered[$0] }.forEach(viewContext.delete)
        try? viewContext.save()
    }
}

// MARK: - Card view used in the grid
struct EntryCard: View {
    let invention: Invention

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(invention.title ?? "Untitled")
                .font(.headline)
                .lineLimit(2)

            Text(invention.details ?? "")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(4)

            if let s = invention.linkString,
               let url = URL(string: s) {
                Link(destination: url) {
                    Text(s)
                        .font(.footnote)
                        .underline()
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.gray.opacity(0.25))
        )
    }
}
