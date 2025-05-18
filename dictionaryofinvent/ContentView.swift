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
        // Main content
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filtered) { inv in
                    Button {
                        editing = inv
                    } label: {
                        EntryCard(invention: inv)
                    }
                    .buttonStyle(ScaleButtonStyle())
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
            .animation(.easeInOut(duration: 0.25), value: filtered)
        }
        .sheet(item: $editing) { inv in
            EditInventionView(invention: inv)
                .environment(\.managedObjectContext, viewContext)
        }
        // Put search & add in the unified title‑bar toolbar
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 12) {
                    TextField("Search inventions…", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .font(.title2)
                        .frame(width: 320)

                    Button(action: add) {
                        Image(systemName: "plus")
                    }
                    .font(.title2)
                    .keyboardShortcut("n", modifiers: [.command])
                }
            }
        }
    }

    // MARK: - Helpers
    private var filtered: [Invention] {
        guard !searchText.isEmpty else { return Array(inventions) }
        let q = searchText.lowercased()
        return inventions.filter {
            ($0.title ?? "").lowercased().contains(q) ||
            ($0.details ?? "").lowercased().contains(q) ||
            ($0.linkString ?? "").lowercased().contains(q)
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
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(invention.title ?? "Untitled")
                .font(.title3)
                .lineLimit(2)

            Text(invention.details ?? "")
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(4)

            if let s = invention.linkString,
               let url = URL(string: s) {
                Link(destination: url) {
                    Text(s)
                        .font(.callout)
                        .underline()
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity,
               minHeight: 160, maxHeight: 160,
               alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(hovering ? Color.secondary.opacity(0.15)
                                : Color(.windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.gray.opacity(0.20))
        )
        .shadow(radius: hovering ? 4 : 2)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .animation(.easeInOut(duration: 0.15), value: hovering)
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
            .font(.title3)

            TextEditor(text: Binding(
                get: { invention.details ?? "" },
                set: { invention.details = $0 }
            ))
            .padding(6)
            .frame(height: 160)
            .scrollContentBackground(.hidden)            // hide native dark bg
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.textBackgroundColor))   // light fill like text fields
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.secondary)                  // same subtle border
            )

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

// MARK: - Helpers
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
