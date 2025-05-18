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
            // Simple details pane for now
            if let selected = inventions.first {  // placeholder
                VStack(alignment: .leading, spacing: 12) {
                    Text(selected.title ?? "Untitled")
                        .font(.title2)
                    Text(selected.details ?? "")
                    if let s = selected.linkString,
                       let url = URL(string: s) {
                        Link(s, destination: url)
                    }
                }
                .padding()
            } else {
                Text("Select an invention")
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
