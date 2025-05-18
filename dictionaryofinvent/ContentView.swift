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

    /// When non‑nil, shows the edit sheet for this invention
    @State private var editing: Invention?

    // Grid definition for the detail pane
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 260), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top bar with search field and Add button
            HStack(alignment: .center, spacing: 12) {
                TextField("Search inventions…", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 320)

                Spacer()

                Button {
                    add()
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 4)

            Divider()

            // Grid of cards
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filtered) { inv in
                        Button {
                            editing = inv
                        } label: {
                            EntryCard(invention: inv)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                delete(inv)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .sheet(item: $editing) { inv in
            EditInventionView(invention: inv)
                .environment(\.managedObjectContext, viewContext)
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
        editing = new            // open sheet
    }
    
    private func delete(_ invention: Invention) {
        viewContext.delete(invention)
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
        .contentShape(Rectangle())
    }
}

// MARK: - Edit sheet
struct EditInventionView: View {
    @ObservedObject var invention: Invention
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var ctx

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Title", text: Binding(
                get: { invention.title ?? "" },
                set: { invention.title = $0 }
            ))
            .textFieldStyle(.roundedBorder)

            TextEditor(text: Binding(
                get: { invention.details ?? "" },
                set: { invention.details = $0 }
            ))
            .frame(height: 160)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary))

            TextField("Link (optional)", text: Binding(
                get: { invention.linkString ?? "" },
                set: { invention.linkString = $0 }
            ))
            .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("Done") {
                    try? ctx.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(minWidth: 400)
    }
}
