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
    }
}
