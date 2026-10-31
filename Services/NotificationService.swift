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

        // Termin schon vorbei -> keine Erinnerung mehr planen
        let now = Date()
        guard nextDate > now else { return }

        // Vorlauf-Tag schon vorbei (z.B. Vorlauf 3 Tage, Termin in 2 Tagen) -> naechster 9-Uhr-Zeitpunkt
        var fireDate = notificationDate
        var fireComponents = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
        fireComponents.hour = 9
        fireComponents.minute = 0
        if let fireAt = Calendar.current.date(from: fireComponents), fireAt <= now {
            fireDate = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: now)) ?? now
            if let todayNine = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: now), todayNine > now {
                fireDate = todayNine
            }
        }
        let remainingDays = max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: fireDate), to: Calendar.current.startOfDay(for: nextDate)).day ?? daysBeforeEvent)

        // Create notification content (localized)
        let content = UNMutableNotificationContent()
        content.title = "Hippominder"
        if remainingDays == 0 {
            content.body = "\(horse.name): \(eventType.localizedName) " + String(localized: "heute fällig!")
        } else {
            content.body = "\(horse.name): \(eventType.localizedName) " + String(localized: "in") + " \(remainingDays) " + String(localized: "Tagen fällig!")
        }
        content.sound = .default

        // Create trigger at 9:00 AM on notification day
        var components = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
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

    /// Geplante Benachrichtigungen entfernen, deren Pferd nicht mehr existiert
    /// (z.B. wenn die App direkt nach dem Loeschen beendet wurde)
    func removeOrphanedNotifications(validHorseIDs: [UUID]) {
        let validPrefixes = validHorseIDs.map { $0.uuidString }
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let orphaned = requests
                .map(\.identifier)
                .filter { identifier in !validPrefixes.contains { identifier.hasPrefix($0) } }
            if !orphaned.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: orphaned)
            }
        }
    }

    #if DEBUG
    /// Debug-Hilfe: Berechtigungsstatus und alle geplanten Benachrichtigungen auf die Konsole schreiben
    func debugDumpPending() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            print("NOTIFY_AUTH: \(settings.authorizationStatus.rawValue)")
            center.getPendingNotificationRequests { requests in
                print("NOTIFY_PENDING_COUNT: \(requests.count)")
                for request in requests {
                    var when = "-"
                    if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                       let date = trigger.nextTriggerDate() {
                        when = ISO8601DateFormatter().string(from: date)
                    }
                    print("NOTIFY_PENDING: \(request.identifier) | \(when) | \(request.content.body)")
                }
            }
        }
    }
    #endif
}
