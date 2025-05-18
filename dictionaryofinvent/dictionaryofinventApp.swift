//
//  dictionaryofinventApp.swift
//  dictionaryofinvent
//
//  Created by Jason Qin on 2025-05-18.
//

import SwiftUI

@main
struct dictionaryofinventApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
