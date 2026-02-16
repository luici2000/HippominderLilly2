//
//  HippominderWatchApp.swift
//  Hippominder Watch App
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 13. Februar 2026
//  Version: 1.0.0
//
//  Beschreibung: Watch App Einstiegspunkt – Companion fuer die iOS App
//

import SwiftUI
import SwiftData

@main
struct HippominderWatchApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Horse.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .onAppear {
                    WatchSyncReceiver.shared.configure(with: sharedModelContainer)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
