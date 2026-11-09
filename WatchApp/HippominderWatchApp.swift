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
    /// Die Uhr bleibt bewusst oertlich statt an iCloud: im Stall hat sie oft
    /// kein Netz, und der Direktfunk zum iPhone traegt auch dann.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Horse.self])
        do {
            return try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, cloudKitDatabase: .none)]
            )
        } catch {
            // Lieber ohne Sicherung laufen als gar nicht starten
            print("Kein dauerhafter Speicher auf der Uhr: \(error)")
            return try! ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
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
