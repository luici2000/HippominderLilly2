//
//  HippominderApp.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 24. Januar 2026
//  Geaendert: 12. Februar 2026, 22:00 Uhr
//  Version: 2.0.0
//
//  Beschreibung: Haupt-App-Einstiegspunkt mit SwiftData Container
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct HippominderApp: App {

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
            ContentView()
                .onAppear {
                    scheduleAllNotifications()
                }
        }
        .modelContainer(sharedModelContainer)
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
