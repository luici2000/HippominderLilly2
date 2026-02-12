//
//  NotificationService.swift
//  Hippominder
//
//  Autor: Mathias Hubrich & Claude (Anthropic)
//  Erstellt: 24. Januar 2026
//  Geaendert: 12. Februar 2026, 22:00 Uhr
//  Version: 2.0.0
//
//  Beschreibung: Lokale Benachrichtigungen fuer Termine
//

import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    /// Schedule a notification for a specific event type
    func scheduleNotification(
        for horse: Horse,
        eventType: Horse.EventType,
        daysBeforeEvent: Int
    ) {
        let center = UNUserNotificationCenter.current()

        // Remove existing notification for this horse+event
        let identifier = "\(horse.id.uuidString)-\(eventType.rawValue)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        // Calculate next appointment date
        let nextDate = horse.naechsterTermin(fuer: eventType)

        // Calculate notification date (X days before)
        guard let notificationDate = Calendar.current.date(byAdding: .day, value: -daysBeforeEvent, to: nextDate) else {
            return
        }

        // Only schedule if notification date is in the future
        guard notificationDate > Date() else { return }

        // Create notification content (localized)
        let content = UNMutableNotificationContent()
        content.title = "Hippominder"
        content.body = "\(horse.name): \(eventType.localizedName) " + String(localized: "in") + " \(daysBeforeEvent) " + String(localized: "Tagen fällig!")
        content.sound = .default

        // Create trigger at 9:00 AM on notification day
        var components = Calendar.current.dateComponents([.year, .month, .day], from: notificationDate)
        components.hour = 9
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Schedule
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    /// Schedule notifications for all event types of a horse
    func scheduleAllNotifications(for horse: Horse) {
        for eventType in Horse.EventType.allCases {
            scheduleNotification(
                for: horse,
                eventType: eventType,
                daysBeforeEvent: horse.benachrichtigungTageVorher
            )
        }
    }

    /// Remove all notifications for a horse
    func removeAllNotifications(for horse: Horse) {
        let center = UNUserNotificationCenter.current()
        let identifiers = Horse.EventType.allCases.map { "\(horse.id.uuidString)-\($0.rawValue)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
