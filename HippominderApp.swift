//
//  HippominderApp.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 24. Januar 2026
//  Geaendert: 13. Februar 2026
//  Version: 3.0.0
//
//  Beschreibung: Haupt-App-Einstiegspunkt mit SwiftData Container
//  Unterstuetzt iOS, macOS (feste Fenstergroesse)
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct HippominderApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        requestNotificationPermission()
    }

    var sharedModelContainer: ModelContainer = Self.ladeContainer()

    /// Pferde liegen in iCloud, damit sie auf iPhone und Mac dieselben sind
    /// und ein verlorenes Geraet sie nicht mitnimmt. Kostet nichts: CloudKit
    /// nutzt den iCloud-Speicher des Nutzers, und Termine sind winzig.
    ///
    /// Ist iCloud abgeschaltet oder nicht eingerichtet, laeuft die App rein
    /// oertlich weiter. Frueher stand hier ein fatalError - die App waere in
    /// dem Fall gar nicht erst gestartet.
    private static func ladeContainer() -> ModelContainer {
        let schema = Schema([Horse.self])

        do {
            return try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)]
            )
        } catch {
            print("iCloud nicht verfuegbar, arbeite oertlich weiter: \(error)")
        }

        do {
            return try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, cloudKitDatabase: .none)]
            )
        } catch {
            // Auch oertlich kein Speicher: lieber ohne Sicherung arbeiten
            // lassen als den Start zu verweigern
            print("Kein dauerhafter Speicher moeglich: \(error)")
            return try! ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            #if os(macOS)
            MacContentView()
                .onAppear {
                    scheduleAllNotifications()
                }
                .frame(minWidth: 700, idealWidth: 900, maxWidth: 1100,
                       minHeight: 500, idealHeight: 650, maxHeight: 800)
            #else
            ContentView()
                .onAppear {
                    scheduleAllNotifications()
                    WatchSyncService.shared.configure(with: sharedModelContainer)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        WatchSyncService.shared.syncToWatch()
                    }
                    // Auch beim Verlassen: der Nutzer hat gerade vielleicht
                    // einen Termin eingetragen, dann muss die Zahl sinken
                    refreshBadge()
                }
            #endif
        }
        .modelContainer(sharedModelContainer)
        #if os(macOS)
        .defaultSize(width: 900, height: 650)
        .windowResizability(.contentSize)
        #endif
    }

    private func requestNotificationPermission() {
        #if DEBUG
        // Fuer Screenshots aus dem Simulator: die Systemfrage laesst sich
        // ohne Bildschirm nicht wegtippen und verdeckt sonst die Ansicht
        if ProcessInfo.processInfo.arguments.contains("-skipNotificationPrompt") { return }
        #endif
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
    }

    /// Schedule notifications for all horses on app launch
    private func scheduleAllNotifications() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Horse>()
        guard let horses = try? context.fetch(descriptor) else { return }

        for horse in horses {
            NotificationService.shared.scheduleAllNotifications(for: horse)
        }
        NotificationService.shared.removeOrphanedNotifications(validHorseIDs: horses.map(\.id))
        NotificationService.shared.updateBadge(for: horses)
        #if os(iOS)
        AppIconService.aktualisiere(for: horses)
        #endif
    }

    /// Zahl am App-Symbol neu berechnen. Tage vergehen auch ohne die App,
    /// darum bei jedem Wechsel der Szene statt nur beim Start.
    private func refreshBadge() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Horse>()
        guard let horses = try? context.fetch(descriptor) else { return }
        NotificationService.shared.updateBadge(for: horses)
        #if os(iOS)
        AppIconService.aktualisiere(for: horses)
        #endif
    }
}
