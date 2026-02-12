//
//  NotificationService.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 24. Januar 2026
//  Geaendert: 25. Januar 2026, 12:00 Uhr
//  Version: 1.1.0
//
//  Beschreibung: Benachrichtigungen fuer Termine
//

import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func scheduleNotification(
        for horse: Horse,
        eventType: Horse.EventType,
        daysBeforeEvent: Int
    ) {
        let center = UNUserNotificationCenter.current()

        // Bestehende Benachrichtigung entfernen
        let identifier = "\(horse.id.uuidString)-\(eventType.rawValue)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        // Naechsten Termin berechnen
        let nextDate = horse.naechsterTermin(fuer: eventType)

        // Benachrichtigungsdatum berechnen
        guard let notificationDate = Calendar.current.date(byAdding: .day, value: -daysBeforeEvent, to: nextDate) else {
            return
        }

        // Nur wenn das Datum in der Zukunft liegt
        guard notificationDate > Date() else { return }

        // Benachrichtigung erstellen
        let content = UNMutableNotificationContent()
        content.title = "Hippominder"
        content.body = "\(horse.name): \(eventType.rawValue) in \(daysBeforeEvent) Tagen faellig!"
        content.sound = .default

        // Trigger erstellen
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Request erstellen
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // Hinzufuegen
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    func scheduleAllNotifications(for horse: Horse) {
        for eventType in Horse.EventType.allCases {
            scheduleNotification(
                for: horse,
                eventType: eventType,
                daysBeforeEvent: horse.benachrichtigungTageVorher
            )
        }
    }

    func removeAllNotifications(for horse: Horse) {
        let center = UNUserNotificationCenter.current()
        let identifiers = Horse.EventType.allCases.map { "\(horse.id.uuidString)-\($0.rawValue)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
